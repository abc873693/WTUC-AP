import 'package:ap_common/models/score_data.dart';
import 'package:ap_common/models/semester_data.dart';
import 'package:ap_common/scaffold/score_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:wtuc_ap/api/helper.dart';
import 'package:wtuc_ap/utils/app_localizations.dart';

class ScorePage extends StatefulWidget {
  static const String routerName = '/score';

  @override
  ScorePageState createState() => ScorePageState();
}

class ScorePageState extends State<ScorePage> {
  ApLocalizations ap;

  ScoreState state = ScoreState.loading;

  SemesterData semesterData;

  ScoreData scoreData;

  bool isOffline = false;

  String customStateHint = '';

  @override
  void initState() {
    _getSemester();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    return ScoreScaffold(
      state: state,
      scoreData: scoreData,
      customHint: "${isOffline ? "${ap.offlineScore}\n" : ""}"
          "${AppLocalizations.of(context).scoreClickHint}",
      customStateHint: customStateHint,
      semesterData: semesterData,
      onSelect: (index) {
        this.semesterData.currentIndex = index;
        _getSemesterScore();
      },
      onScoreSelect: (index) {
        final score = scoreData.scores[index];
        DialogUtils.showDefault(
          context: context,
          title: score.title,
          content: "${ap.generalScore}：${score.generalScore}\n"
              "${ap.midtermScore}：${score.middleScore}\n"
              "${ap.finalScore}：${score.finalScore}",
        );
      },
      middleTitle: ap.credits,
      middleScoreBuilder: (index) {
        return Center(
          child: Text(scoreData.scores[index].units),
        );
      },
      onRefresh: () async {
        await _getSemesterScore();
        return null;
      },
      details: [],
    );
  }

  void _getSemester() async {
    Helper.instance.getSemester(
      callback: GeneralCallback<SemesterData>(
        onFailure: null,
        onError: null,
        onSuccess: (data) {
          setState(() {
            semesterData = data;
          });
          _getSemesterScore();
        },
      ),
    );
  }

  _getSemesterScore() async {
    Helper.instance.getScores(
      semester: semesterData.currentSemester,
      callback: GeneralCallback(
        onSuccess: (ScoreData data) {
          if (mounted)
            setState(() {
              scoreData = data;
              isOffline = false;
              // courseData.save(semesterData.currentSemester.cacheSaveTag);
              state = scoreData?.scores == null || scoreData.scores.length == 0
                  ? ScoreState.empty
                  : ScoreState.finish;
            });
        },
        onFailure: (DioError e) async {
          setState(() {
            state = ScoreState.custom;
            customStateHint = e.i18nMessage;
          });
        },
        onError: (GeneralResponse generalResponse) async {
          setState(() {
            state = ScoreState.custom;
            customStateHint = ap.unknownError;
          });
        },
      ),
    );
  }

//  Future<bool> _loadOfflineScoreData() async {
//    scoreData = ScoreData.load(selectSemester.cacheSaveTag);
//    if (mounted) {
//      setState(() {
//        isOffline = true;
//        if (scoreData == null)
//          state = ScoreState.offlineEmpty;
//        else {
//          state = ScoreState.finish;
//        }
//      });
//    }
//    return scoreData == null;
//  }
}
