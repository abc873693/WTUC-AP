import 'package:ap_common/resources/ap_theme.dart';
import 'package:ap_common/scaffold/login_scaffold.dart';
import 'package:ap_common/utils/ap_localizations.dart';
import 'package:ap_common/utils/ap_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sprintf/sprintf.dart';
import 'package:wtuc_ap/api/helper.dart';
import 'package:wtuc_ap/utils/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  final String username;

  const ChangePasswordPage({
    Key key,
    @required this.username,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _passwordConfirmFocusNode = FocusNode();

  bool get isTablet => MediaQuery.of(context).size.shortestSide >= 600;

  String description = '';

  @override
  void initState() {
    Future.microtask(
      () => _getData(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      backgroundColor: ApTheme.of(context).blue,
      resizeToAvoidBottomInset: orientation == Orientation.portrait,
      body: AutofillGroup(
        child: KeyboardDismissOnTap(
          child: Container(
            alignment: const Alignment(0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: _content(orientation),
          ),
        ),
      ),
    );
  }

  Widget _content(Orientation orientation) {
    final ap = ApLocalizations.of(context);
    final app = AppLocalizations.of(context);
    final descriptionText = Text(
      app.changePasswordDescription,
      style: TextStyle(fontSize: 18.0),
    );
    final List<Widget> forms = [
      Text(
        ap.changePassword,
        style: TextStyle(fontSize: 20.0),
      ),
      ApTextField(
        obscureText: true,
        textInputAction: TextInputAction.next,
        controller: _password,
        focusNode: _passwordFocusNode,
        nextFocusNode: _passwordConfirmFocusNode,
        labelText: ap.newPassword,
        autofillHints: [AutofillHints.newPassword],
      ),
      ApTextField(
        obscureText: true,
        textInputAction: TextInputAction.send,
        controller: _passwordConfirm,
        focusNode: _passwordConfirmFocusNode,
        onSubmitted: (text) {
          _passwordConfirmFocusNode.unfocus();
          _send();
        },
        labelText: ap.newPasswordConfirm,
      ),
      SizedBox(height: 30.0),
      ApButton(
        text: ap.confirm,
        onPressed: _send,
      ),
      SizedBox(height: 16.0),
      Text(
        app.changePasswordExceptionDescription,
      ),
      SizedBox(height: 8.0),
      InkWell(
        onTap: () {
          ApUtils.launchUrl('https://sso.wzu.edu.tw/Portal/login.htm');
        },
        child: Text(
          app.goToSSOHint,
          style: TextStyle(fontSize: 16.0),
        ),
      ),
    ];
    switch (orientation) {
      case Orientation.portrait:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            mainAxisSize: MainAxisSize.min,
            children: [
              descriptionText,
              ...forms,
            ],
          ),
        );
        break;
      case Orientation.landscape:
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: descriptionText,
              ),
            ),
            SizedBox(width: 16.0),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: forms,
              ),
            ),
          ],
        );
        break;
    }
  }

  void _getData() {
    Helper.instance.getChangePasswordInfo(
      username: widget.username,
      callback: GeneralCallback(
        onFailure: (e) {},
        onError: (e) {},
        onSuccess: (r) {
          setState(() {
            description = r;
          });
        },
      ),
    );
  }

  void _send() {
    int minimumCounts = 8;
    final ap = ApLocalizations.of(context);
    if (_password.text.isEmpty || _passwordConfirm.text.isEmpty) {
      ApUtils.showToast(context, ap.doNotEmpty);
      _passwordFocusNode.requestFocus();
    } else if (_password.text.length < minimumCounts) {
      ApUtils.showToast(
          context, sprintf(ap.newPasswordLeastCharacter, [minimumCounts]));
      _passwordFocusNode.requestFocus();
    } else if (_password.text != _passwordConfirm.text) {
      ApUtils.showToast(context, ap.newPasswordNotMatchHint);
      _passwordConfirmFocusNode.requestFocus();
    } else {
      Helper.instance.changePassword(
        username: widget.username,
        password: _password.text,
        passwordConfirm: _passwordConfirm.text,
        callback: GeneralCallback(
          onFailure: (e) => ApUtils.showToast(context, e.i18nMessage),
          onError: (e) => ApUtils.showToast(context, e.message),
          onSuccess: (r) {
            ApUtils.showToast(
              context,
              ApLocalizations.of(context).changePasswordSuccessHint2,
            );
            Navigator.of(context).pop(_password.text);
          },
        ),
      );
    }
  }
}
