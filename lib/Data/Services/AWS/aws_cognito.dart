import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:http/http.dart' as http;
class AWSServices {
  final userPool = CognitoUserPool(
    '${(dotenv.env['POOL_ID'])}',
    '${(dotenv.env['CLIENT_ID'])}',
  );

  Future createInitialRecord(email, password) async {
    debugPrint('Authenticating User...');
    final cognitoUser = CognitoUser(email, userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );
    CognitoUserSession? session;
    try {
      session = await cognitoUser.authenticateUser(authDetails);
      debugPrint('Login Success...');
      print(session!.getAccessToken().getJwtToken());

      const endpoint =
          'https://a7wredygja.execute-api.ap-southeast-1.amazonaws.com/';
      final credentials = CognitoCredentials(
          'ap-southeast-1:fc90cb6d-a484-4fbc-8b9e-95f3d7ca697a', userPool);
      await credentials.getAwsCredentials(session.getIdToken().getJwtToken());
      final awsSigV4Client = AwsSigV4Client(
          credentials.accessKeyId!, credentials.secretAccessKey!, endpoint,
          sessionToken: credentials.sessionToken,
          region: 'ap-southeast-1');

      final signedRequest = SigV4Request(awsSigV4Client,
          method: 'POST',
          path: '/employees',
          body: Map<String, dynamic>.from({
            "empId":"AAA123",
            "name":"Wan",
            "email":"wanmuz86@gmail.com",
            "phone":"012345",
            "address":"123 jalan 123"
          }));

      http.Response? response;
      try {
        response = await http.post(
          Uri.parse(signedRequest.url!),
          body: signedRequest.body,
        );
      } catch (e) {
        print(e);
      }
      print(response?.body);
    } on CognitoUserNewPasswordRequiredException catch (e) {
      debugPrint('CognitoUserNewPasswordRequiredException $e');
    } on CognitoUserMfaRequiredException catch (e) {
      debugPrint('CognitoUserMfaRequiredException $e');
    } on CognitoUserSelectMfaTypeException catch (e) {
      debugPrint('CognitoUserMfaRequiredException $e');
    } on CognitoUserMfaSetupException catch (e) {
      debugPrint('CognitoUserMfaSetupException $e');
    } on CognitoUserTotpRequiredException catch (e) {
      debugPrint('CognitoUserTotpRequiredException $e');
    } on CognitoUserCustomChallengeException catch (e) {
      debugPrint('CognitoUserCustomChallengeException $e');
    } on CognitoUserConfirmationNecessaryException catch (e) {
      debugPrint('CognitoUserConfirmationNecessaryException $e');
    } on CognitoClientException catch (e) {
      debugPrint('CognitoClientException $e');
    } catch (e) {
      print(e);
    }
  }
}
