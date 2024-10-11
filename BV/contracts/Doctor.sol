// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Patient.sol'; // Import the PatientRecord contract

contract DoctorContract {
    PatientRecord private patientRecord;

    // Events to log access or denied access
    event AccessGranted(address indexed doctor, uint256 patientId);
    event AccessDenied(address indexed doctor, uint256 patientId);
    event DiagnosisSubmitted(address indexed doctor, uint256 patientId, string details);

    constructor(address _patientRecordAddress) {
        patientRecord = PatientRecord(_patientRecordAddress);
    }

    // Modifier to ensure only doctors with access can view records
modifier onlyDoctorWithAccess(uint256 patientId) {
    require(patientRecord.hasDoctorAccess(msg.sender, patientId), "Access denied: Doctor does not have access to this patient's records");
    _;
}

    // Function to allow a doctor to view a patient's records if they have access
function viewPatientRecord(uint256 patientId) public onlyDoctorWithAccess(patientId) returns (PatientRecord.Record memory) {
    PatientRecord.Record memory patientRecordDetails = patientRecord.getRecord(patientId);
    emit AccessGranted(msg.sender, patientId);
    return patientRecordDetails;
}

    // Function to add a diagnosis for a patient
    function addDiagnosis(
        uint256 patientId,
        string memory doctorName,
        string memory doctorAddress,
        string memory details
    ) public onlyDoctorWithAccess(patientId) {
        // Call the PatientRecord contract to add the diagnosis
        patientRecord.addDiagnosis(patientId, doctorName, doctorAddress, details);
        emit DiagnosisSubmitted(msg.sender, patientId, details);
    }

    // Function to view the full diagnosis history of a patient
    function viewFullDiagnoses(uint256 patientId) public view onlyDoctorWithAccess(patientId) returns (PatientRecord.Diagnosis[] memory) {
        return patientRecord.getFullDiagnoses(patientId);
    }

    // Function to view the latest diagnosis of a patient
    function viewLatestDiagnosis(uint256 patientId) public view onlyDoctorWithAccess(patientId) returns (PatientRecord.Diagnosis memory) {
        return patientRecord.getLatestDiagnosis(patientId);
    }
}
