// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VitalSignsContract {
    struct VitalSigns {
        uint256 pulseRate;
        uint256 bodyTemperature;
        uint256 respirationRate;
        uint256 bloodOxygenLevel;
        uint256 systolicBloodPressure;
        uint256 diastolicBloodPressure;
        string ecgWaveform;
        string spo2Waveform;
        string respirationWaveform;
        uint256 timestamp;
        string sensorId;
    }

    // Mapping of patientId to an array of VitalSigns for each sensor
    mapping(uint256 => mapping(string => VitalSigns[])) private vitalSignsHistory;

    // Track sensorIds for each patientId
    mapping(uint256 => string[]) private patientSensors;

    event VitalSignsAdded(uint256 patientId, string sensorId, uint256 timestamp);

    // Function to add vital signs from a specific sensor for a patient
    function addVitalSigns(
        uint256 _patientId,
        string memory _sensorId,
        uint256 _pulseRate,
        uint256 _bodyTemperature,
        uint256 _respirationRate,
        uint256 _bloodOxygenLevel,
        uint256 _systolicBloodPressure,
        uint256 _diastolicBloodPressure,
        string memory _ecgWaveform,
        string memory _spo2Waveform,
        string memory _respirationWaveform
    ) public {
        // Check if the sensor is new for this patient
        if (vitalSignsHistory[_patientId][_sensorId].length == 0) {
            patientSensors[_patientId].push(_sensorId); // Add sensorId to the list for this patient
        }

        VitalSigns memory newVitalSigns = VitalSigns({
            pulseRate: _pulseRate,
            bodyTemperature: _bodyTemperature,
            respirationRate: _respirationRate,
            bloodOxygenLevel: _bloodOxygenLevel,
            systolicBloodPressure: _systolicBloodPressure,
            diastolicBloodPressure: _diastolicBloodPressure,
            ecgWaveform: _ecgWaveform,
            spo2Waveform: _spo2Waveform,
            respirationWaveform: _respirationWaveform,
            timestamp: block.timestamp,
            sensorId: _sensorId
        });

        // Push the new vital signs data to the patient's history for the corresponding sensor
        vitalSignsHistory[_patientId][_sensorId].push(newVitalSigns);

        emit VitalSignsAdded(_patientId, _sensorId, block.timestamp);
    }

    // Function to retrieve the history of vital signs for a specific sensor and patient
    function getVitalSignsHistoryBySensor(uint256 _patientId, string memory _sensorId) public view returns (VitalSigns[] memory) {
        return vitalSignsHistory[_patientId][_sensorId];
    }

    // Function to retrieve the history of all vital signs for a patient from all sensors
    function getAllVitalSignsHistory(uint256 _patientId) public view returns (VitalSigns[] memory) {
        uint totalEntries = 0;

        // Calculate the total number of vital signs entries across all sensors for this patient
        for (uint i = 0; i < patientSensors[_patientId].length; i++) {
            string memory sensorId = patientSensors[_patientId][i];
            totalEntries += vitalSignsHistory[_patientId][sensorId].length;
        }

        // Create a new array to hold all vital signs records
        VitalSigns[] memory allVitalSigns = new VitalSigns[](totalEntries);
        uint index = 0;

        // Populate the array with vital signs data from all sensors
        for (uint i = 0; i < patientSensors[_patientId].length; i++) {
            string memory sensorId = patientSensors[_patientId][i];
            for (uint j = 0; j < vitalSignsHistory[_patientId][sensorId].length; j++) {
                allVitalSigns[index] = vitalSignsHistory[_patientId][sensorId][j];
                index++;
            }
        }

        return allVitalSigns;
    }

    // Function to retrieve all sensor IDs associated with a patient
    function getSensorsByPatient(uint256 _patientId) public view returns (string[] memory) {
        return patientSensors[_patientId];
    }
}
