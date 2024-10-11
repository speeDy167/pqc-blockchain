const PatientRecord = artifacts.require("PatientRecord");
const SensorManager = artifacts.require("SensorManager");
const DoctorContract = artifacts.require("DoctorContract");

module.exports = async function(deployer) {

  await deployer.deploy(PatientRecord);
  const patientRecordInstance = await PatientRecord.deployed();

  await deployer.deploy(SensorManager, patientRecordInstance.address);
 
  await deployer.deploy(DoctorContract, patientRecordInstance.address);
};
