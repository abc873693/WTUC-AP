import 'package:ap_common/resources/ap_icon.dart';
import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/widgets/hint_content.dart';
import 'package:flutter/material.dart';
import 'package:wtuc_ap/api/helper.dart';
import 'package:wtuc_ap/models/teaching_evaluation.dart';
import 'package:wtuc_ap/utils/app_localizations.dart';

enum _State {
  loading,
  error,
  finish,
  filling,
}

class TeachingEvaluationPage extends StatefulWidget {
  @override
  _TeachingEvaluationPageState createState() => _TeachingEvaluationPageState();
}

class _TeachingEvaluationPageState extends State<TeachingEvaluationPage> {
  ApLocalizations ap;
  AppLocalizations app;

  _State state = _State.loading;

  List<TeachingEvaluation> teachingEvaluations;

  String get hintText {
    switch (state) {
      case _State.loading:
        return ap.loading;
      case _State.error:
        return ap.somethingError;
        break;
      case _State.filling:
        return app.filling;
        break;
      default:
        return '';
    }
  }

  @override
  void initState() {
    _getData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ap = ApLocalizations.of(context);
    app = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.teachingEvaluation),
        backgroundColor: ApTheme.of(context).blue,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          setState(() => state = _State.filling);
          await Helper.instance
              .sendTeachingEvaluation(teachingEvaluations: teachingEvaluations);
          _getData();
          setState(() => state = _State.finish);
        },
        label: Text(app.quicklyFillIn),
      ),
      body: _body(),
    );
  }

  Future<void> _getData() async {
    teachingEvaluations = await Helper.instance.getTeachingEvaluation();
    setState(() => state = _State.finish);
  }

  Widget _body() {
    switch (state) {
      case _State.finish:
        return RefreshIndicator(
          onRefresh: () async {
            await _getData();
            return null;
          },
          child: ListView.separated(
            itemCount: teachingEvaluations?.length ?? 0,
            itemBuilder: (_, index) => ListTile(
              title: Text(
                teachingEvaluations[index].title,
              ),
              subtitle: Text(
                teachingEvaluations[index].instructor,
              ),
              trailing: Text(
                teachingEvaluations[index].state,
                style: TextStyle(
                  color: teachingEvaluations[index].isFinish
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ),
            separatorBuilder: (BuildContext context, int index) => Divider(),
          ),
        );
        break;
      case _State.filling:
      case _State.loading:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8.0),
              Text(hintText),
            ],
          ),
        );
      case _State.error:
      default:
        return HintContent(
          icon: ApIcon.error,
          content: hintText,
        );
    }
  }
}
