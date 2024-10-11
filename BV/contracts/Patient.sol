// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./VitalSign.sol";

contract PatientRecord {
    struct Record {
        uint256 patientId;
        string patientName;
        string roomNumber;
        string department;
        string gatewaySignature;
        uint256 timestamp;
    }

    struct Diagnosis {
        string doctorName;
        string doctorAddress;
        string details;
        uint256 timestamp;
    }

    VitalSignsContract public vitalSignsContract;

    mapping(uint256 => Record) private records;
    mapping(uint256 => Diagnosis[]) public diagnoses; // Mapping of patient IDs to diagnoses
    mapping(address => mapping(uint256 => bool)) private doctorAccess; // Mapping of doctor addresses to patient IDs for access control
    mapping(address => bool) public patientAccess; // Public access for patients
    
    function setPatientAccess(bool hasAccess) public {
        patientAccess[msg.sender] = hasAccess;
    }

    event RecordCreated(uint256 patientId, string patientName, uint256 timestamp);
    event DiagnosisAdded(uint256 patientId, string doctorName, string details, uint256 timestamp);
    event DoctorAccessGranted(address doctor, uint256 patientId);
    event DoctorAccessRevoked(address doctor, uint256 patientId);

    constructor(address _vitalSignsContractAddress) {
        vitalSignsContract = VitalSignsContract(_vitalSignsContractAddress);
    }

    // Function to create patient records
    function createRecord(
        uint256 _patientId,
        string memory _patientName,
        string memory _roomNumber,
        string memory _department,
        string memory _gatewaySignature,
        uint256 _timestamp
    ) public {
        records[_patientId] = Record({
            patientId: _patientId,
            patientName: _patientName,
            roomNumber: _roomNumber,
            department: _department,
            gatewaySignature: _gatewaySignature,
            timestamp: _timestamp
        });

        emit RecordCreated(_patientId, _patientName, _timestamp);
    }

    // Function to add doctor access for a specific patient
function addDoctorAccess(address doctor, uint256 patientId) public {
    require(patientAccess[msg.sender], "Only the patient can grant access to doctors");
    doctorAccess[doctor][patientId] = true;

    emit DoctorAccessGranted(doctor, patientId);
}

    // Function to remove doctor access for a specific patient
    function removeDoctorAccess(address doctor, uint256 patientId) public {
        require(patientAccess[msg.sender], "Only the patient can revoke access to doctors");
        doctorAccess[doctor][patientId] = false;

        emit DoctorAccessRevoked(doctor, patientId);
    }

//     function setPatientAccess(bool hasAccess) public {
//     patientAccess[msg.sender] = hasAccess;
// }

    // Function to check if a doctor has access to a patient's records
function hasDoctorAccess(address doctor, uint256 patientId) public view returns (bool) {
    return doctorAccess[doctor][patientId];
}


    // Function to retrieve patient records
    function getRecord(uint256 patientId) public view returns (Record memory) {
        return records[patientId];
    }

    // Function to retrieve the entire history of vital signs for a patient from a specific sensor
    function getVitalSignsHistoryBySensor(uint256 patientId, string memory sensorId) public view returns (VitalSignsContract.VitalSigns[] memory) {
        require(doctorAccess[msg.sender][patientId], "Access denied: Doctor does not have access to this patient's vital signs");

        return vitalSignsContract.getVitalSignsHistoryBySensor(patientId, sensorId);
    }

    // Function to retrieve the entire history of vital signs for a patient from all sensors
    function getAllVitalSignsHistory(uint256 patientId) public view returns (VitalSignsContract.VitalSigns[] memory) {
        require(doctorAccess[msg.sender][patientId], "Access denied: Doctor does not have access to this patient's vital signs");

        return vitalSignsContract.getAllVitalSignsHistory(patientId);
    }

    // Function to retrieve all sensors associated with a patient
    function getSensorsByPatient(uint256 patientId) public view returns (string[] memory) {
        return vitalSignsContract.getSensorsByPatient(patientId);
    }

    // Add a diagnosis to a patient's record
    function addDiagnosis(
        uint256 _patientId,
        string memory _doctorName,
        string memory _doctorAddress,
        string memory _details
    ) public {
        require(doctorAccess[msg.sender][_patientId], "Access denied: Doctor does not have access to this patient's records");

        Diagnosis memory newDiagnosis = Diagnosis({
            doctorName: _doctorName,
            doctorAddress: _doctorAddress,
            details: _details,
            timestamp: block.timestamp
        });

        diagnoses[_patientId].push(newDiagnosis);

        emit DiagnosisAdded(_patientId, _doctorName, _details, block.timestamp);
    }

    // Function to get all diagnoses for a patient
    function getFullDiagnoses(uint256 patientId) public view returns (Diagnosis[] memory) {
        return diagnoses[patientId];
    }

    // Function to get the latest diagnosis for a patient
    function getLatestDiagnosis(uint256 patientId) public view returns (Diagnosis memory) {
        require(diagnoses[patientId].length > 0, "No diagnoses available for this patient");
        return diagnoses[patientId][diagnoses[patientId].length - 1];
    }
}
