import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:ridingpartner_flutter/src/models/record.dart';
import 'package:ridingpartner_flutter/src/models/weather.dart';
import 'package:ridingpartner_flutter/src/pages/loding_page.dart';
import 'package:ridingpartner_flutter/src/pages/setting_page.dart';
import 'package:ridingpartner_flutter/src/provider/auth_provider.dart';
import 'package:ridingpartner_flutter/src/provider/home_record_provider.dart';
import 'package:ridingpartner_flutter/src/provider/setting_provider.dart';
import 'package:ridingpartner_flutter/src/provider/weather_provider.dart';
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  late WeatherProvider _weatherProvider;
  late HomeRecordProvider _homeRecordProvider;
  late List<Record>? records;
  @override
  void initState() {
    super.initState();
    Provider.of<WeatherProvider>(context, listen: false).getWeather();
    Provider.of<HomeRecordProvider>(context, listen: false).getRecord();
  }

  @override
  Widget build(BuildContext context) {
    _weatherProvider = Provider.of<WeatherProvider>(context);
    _homeRecordProvider = Provider.of<HomeRecordProvider>(context);
    records = _homeRecordProvider.ridingRecord;
    developer.log('weather build');

    return Scaffold(
      floatingActionButton: floatingButtons(),
      body: Column(
        children: [
          weatherWidget(),
          Container(
            height: 70,
          ),
          recordWidget(_homeRecordProvider.recordState),
          recommendWidget()
        ],
      ),
    );
  }

  Widget weatherWidget() {
    switch (_weatherProvider.loadingStatus) {
      case WeatherState.searching:
        return Text('날씨를 검색중입니다');
      case WeatherState.empty:
        return Text('날씨를 불러올 수 없습니다.');
      case WeatherState.completed:
        Weather weather = _weatherProvider.weather;
        return Text(
            '${weather.condition} ${getWeatherIcon(weather.conditionId ?? 800)} 현재 온도 : ${weather.temp}° 습도 : ${weather.humidity}%');
      default:
        return Text('날씨를 검색중입니다');
    }
  }

  Widget recordWidget(RecordState state) {
    switch (state) {
      case RecordState.empty:
        return Container(
          child: Text('데이터가 없습니다.'),
        );
      case RecordState.fail:
        return Container(
          child: Text('데이터 로드에 실패했습니다. 네트워크를 확인해주세요'),
        );
      case RecordState.loading:
        return Container(
          child: Text('데이터 로드중'),
        );
      case RecordState.success:
        return Column(
          children: [
            lastRecord(),
            lastRidingProgress(),
            recordChart(),
          ],
        );
      default:
        return Container(
          child: Text('데이터 로드중'),
        );
    }
  }

  Widget lastRecord() {
    return Column(
      children: [
        Text(records!.last.distance.toString()),
        Text(records!.last.timestamp.toString())
      ],
    );
  }

  Widget lastRidingProgress() {
    double percent = records!.last.distance ?? 3 / 10;
    return Column(
      children: [
        Container(
          alignment: FractionalOffset(percent, 1 - percent),
          child: FractionallySizedBox(
              child: Image.asset('assets/icons/cycling_person.png',
                  width: 30, height: 30, fit: BoxFit.cover)),
        ),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          percent: percent,
          lineHeight: 10,
          backgroundColor: Colors.black38,
          progressColor: Colors.indigo.shade900,
          width: MediaQuery.of(context).size.width,
        )
      ],
    );
  }

  Widget recordChart() {
    return AspectRatio(
        aspectRatio: 2,
        child: LineChart(LineChartData(lineBarsData: [
          LineChartBarData(
              spots: records!.map((data) => FlSpot(1, data.distance!)).toList())
        ])));
  }

  Widget? floatingButtons() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      visible: true,
      curve: Curves.bounceIn,
      backgroundColor: Colors.indigo.shade900,
      children: [
        SpeedDialChild(
            child: const Icon(Icons.settings_sharp, color: Colors.white),
            label: "설정",
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 13.0),
            backgroundColor: Colors.indigo.shade900,
            labelBackgroundColor: Colors.indigo.shade900,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider(
                        create: (context) => SettingProvider(),
                        child: SettingPage(),
                      )));
            }),
        SpeedDialChild(
          child: const Icon(
            Icons.add_chart_rounded,
            color: Colors.white,
          ),
          label: "내 기록",
          backgroundColor: Colors.indigo.shade900,
          labelBackgroundColor: Colors.indigo.shade900,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white, fontSize: 13.0),
          onTap: () {},
        )
      ],
    );
  }

  Widget recommendWidget() {
    return Container(
      child: Row(
        children: [recommendRoute(), recommendRoute()],
      ),
    );
  }

  Widget recommendRoute() => Flexible(
        child: Card(
            semanticContainer: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            margin: const EdgeInsets.all(10),
            child: InkWell(
              onTap: () {},
              child: Image.asset(
                'assets/images/places/lotus_flower_theme_park.jpeg',
                fit: BoxFit.fill,
              ),
            )),
        flex: 1,
      );

  String getWeatherIcon(int condition) {
    if (condition < 300) {
      return '🌩';
    } else if (condition < 400) {
      return '🌧';
    } else if (condition < 600) {
      return '☔️';
    } else if (condition < 700) {
      return '☃️';
    } else if (condition < 800) {
      return '🌫';
    } else if (condition == 800) {
      return '☀️';
    } else if (condition <= 804) {
      return '☁️';
    } else {
      return '🤷‍';
    }
  }
}
