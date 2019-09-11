package config

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"log"
	"os"
)

// CreateConfigFactoryFromJSON is a utility method that creates
// a JMS ConfigionFactory object that is populated with properties from values
// stored in two external files on the file system.
//
// The calling application provides the fully qualified path to the location of
// the config-file as the parameter. If empty string is provided then the default
// location and name is assumed as follows;
//   - $HOME/queue.config.json
func CreateConfig() (cf ConfigStructur, err error) {
	return CreateConfigFactory("")
}
func CreateConfigFactory(configFileName string) (cf ConfigStructur, err error) {

	// If the caller has not explicitly specified a path in which to find these
	// files then assume that they are in the default location (/Downloads)
	if configFileName == "" {
		configFileName = os.Getenv("HOME") + "/queue.config.json"
	}
	// Attempt to read the Configuration info file at the specified location.
	// If we get an error then there is no way to proceed successfully, so
	// terminate the program immediately.
	configContent, err := ioutil.ReadFile(configFileName)
	if err != nil {
		log.Print("Error reading file from " + configFileName)
		return ConfigStructur{}, err
	}

	// Having successfully opened the config info file, unmarshall the
	// JSON into a map and parse out the individual values that we need to
	// use in order to populate the ConfigFactory object.
	var configMap map[string]*json.RawMessage
	err = json.Unmarshal(configContent, &configMap)
	if err != nil {
		log.Print("Failure during unmarshalling file from JSON: " + configFileName)
		return ConfigStructur{}, err
	}

	var managerName, hostName, channelName string
	var portNumber int

	managerName, err = jsonString("managerName", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}
	hostName, err = jsonString("hostName", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}
	portNumber, err = jsonNumber("portNumber", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}
	channelName, err = jsonString("channelName", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}

	var mqUser, mqPass string
	mqUser, err = jsonString("mqUser", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}
	mqPass, err = jsonString("mqPass", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}

	var queueName string
	queueName, err = jsonString("queueName", configMap, configFileName)
	if err != nil {
		return ConfigStructur{}, err
	}
	// Use the parsed values to initialize the attributes of the Impl object.
	cf = ConfigStructur{
		ManagerName:	managerName,
		Hostname:      	hostName,
		PortNumber:    	portNumber,
		ChannelName:   	channelName,
		UserName:      	mqUser,
		Password:      	mqPass,
		QueueName: 	   	queueName,
	}

	// Give the populated ConfigFactory back to the caller.
	return cf, nil

}

// Extract a specified string value from the map that we generated from a JSON object
func jsonString(attributeName string, mapData map[string]*json.RawMessage, fileName string) (value string, err error) {
	var valueStr string
	if mapData[attributeName] == nil {
		return "", errors.New("Unable to find " + attributeName + " in " + fileName)
	}
	err = json.Unmarshal(*mapData[attributeName], &valueStr)
	return valueStr, err
}

// Extract a specified int value from the map that we generated from a JSON object
func jsonNumber(attributeName string, mapData map[string]*json.RawMessage, fileName string) (value int, err error) {
	var valueNum int
	if mapData[attributeName] == nil {
		return 0, errors.New("Unable to find " + attributeName + " in " + fileName)
	}
	err = json.Unmarshal(*mapData[attributeName], &valueNum)
	return valueNum, err
}
