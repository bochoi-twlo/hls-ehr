curl -X POST -k -H 'Content-Type: application/json' -i http://localhost:80/oauth2/default/registration --data '{
   "application_type": "private",
   "redirect_uris":
     ["https://client.example.org/callback"],
   "post_logout_redirect_uris":
     ["https://client.example.org/logout/callback"],
   "client_name": "HLS Flex Blueprint",
   "token_endpoint_auth_method": "client_secret_post",
   "contacts": ["bochoi@twilio.com", "bochoi@twilio.com"],
   "scope": "openid offline_access api:oemr api:fhir api:port user/allergy.read user/allergy.write user/appointment.read user/appointment.write user/dental_issue.read user/dental_issue.write user/document.read user/document.write user/drug.read user/encounter.read user/encounter.write user/facility.read user/facility.write user/immunization.read user/insurance.read user/insurance.write user/insurance_company.read user/insurance_company.write user/insurance_type.read user/list.read user/medical_problem.read user/medical_problem.write user/medication.read user/medication.write user/message.write user/patient.read user/patient.write user/practitioner.read user/practitioner.write user/prescription.read user/procedure.read user/soap_note.read user/soap_note.write user/surgery.read user/surgery.write user/vital.read user/vital.write user/AllergyIntolerance.read user/CareTeam.read user/Condition.read user/Coverage.read user/Encounter.read user/Immunization.read user/Location.read user/Medication.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Organization.write user/Patient.read user/Patient.write user/Practitioner.read user/Practitioner.write user/PractitionerRole.read user/Procedure.read patient/encounter.read patient/patient.read patient/AllergyIntolerance.read patient/CareTeam.read patient/Condition.read patient/Encounter.read patient/Immunization.read patient/MedicationRequest.read patient/Observation.read patient/Patient.read patient/Procedure.read"
  }'



curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded' -i 'http://localhost:80/oauth2/default/token' \
--data 'grant_type=refresh_token&client_id=mC-4UrqaLeedy2y1527BRfa_FHDYk-ON2G5KSNx8ChU&client_secret=j21ecvLmFi9HPc_Hv0t7Ptmf1pVcZQLtHjIdU7U9tkS9WAjFJwVMav0G8ogTJ62q4BATovC7BQ19Qagc4x9BBg'

curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded' -i 'http://localhost:80/oauth2/default/token' \
--data 'client_id=mC-4UrqaLeedy2y1527BRfa_FHDYk-ON2G5KSNx8ChU&user_role=users&username=admin&password=pass&grant_type=password&scope=openid%20offline_access%20api%3Aport%20api%3Afhir%20patient%2Fencounter.read%20patient%2Fpatient.read%20patient%2FAllergyIntolerance.read%20patient%2FCareTeam.read%20patient%2FCondition.read%20patient%2FEncounter.read%20patient%2FImmunization.read%20patient%2FMedicationRequest.read%20patient%2FObservation.read%20patient%2FPatient.read%20patient%2FProcedure.read'

curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded' -i 'http://localhost:80/oauth2/default/token' \
--data 'client_id=mC-4UrqaLeedy2y1527BRfa_FHDYk-ON2G5KSNx8ChU&user_role=users&username=admin&password=pass&grant_type=password&scope=openid%20offline_access%20api%3Aport%20api%3Afhir%20patient.read'

%20patient%2Fencounter.read%20patient%2Fpatient.read%20patient%2FAllergyIntolerance.read%20patient%2FCareTeam.read%20patient%2FCondition.read%20patient%2FEncounter.read%20patient%2FImmunization.read%20patient%2FMedicationRequest.read%20patient%2FObservation.read%20patient%2FPatient.read%20patient%2FProcedure.read&user_role=users&username=admin&password=pass'



curl -X GET 'http://localhost:80/apis/default/fhir/Patient' \
  -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJtQy00VXJxYUxlZWR5MnkxNTI3QlJmYV9GSERZay1PTjJHNUtTTng4Q2hVIiwianRpIjoiOTZkM2VmMzkxNWIxMTViM2MxNDViYzgxYmJiNGFhMjMyZjliOGE3ZWUxZGUyMDQ2OWQ4YWMwZDk1YWE0NThlOTRkOGMwNDMyOTdiM2NjMTciLCJpYXQiOjE2NDM4NDgwNDYsIm5iZiI6MTY0Mzg0ODA0NiwiZXhwIjoxNjQzODUxNjQ2LCJzdWIiOiI5NTdmOGVhMi0xMTk4LTRkZGYtOWZiYy1lMDY3MTkwNzhkNGYiLCJzY29wZXMiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiLCJhcGk6cG9ydCIsImFwaTpmaGlyIiwic2l0ZTpkZWZhdWx0Il19.cj_f7bLf7B_z69Wp__skUAJNQMQPmUMIaFpGWfVd56CsjOHZoALxr4M7uTMf7LuD2O4oOfGubnqjSHDeHn7QMJ8TX5AGNELWgOUTBZNAchzmgw1_cFfEf_eY9CmnTyqgCEmomUfE4p3ILO9Qvx8E3O80SLmG2zFX9VfmB8cqms6GS9uSThN0sRPYssKdziLYHfwogo3Nh-NmJf5GTnphDNseJo2ojQTkqjHBFJBhu3U_ye_QSiLs5IpS4X3B3YBWbP78NrDzPQQiwz65NJmoUIj2f4cIcdjS6b2EVxOEjoYRxg2ilw-rZJ_9FVwH9U9lQQx2DvTAJQaU5UWo3f4gXg'
