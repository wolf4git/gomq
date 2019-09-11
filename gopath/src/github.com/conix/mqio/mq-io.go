/*
 * Copyright (c) IBM Corporation 2019
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0, which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package main

import (
	"encoding/hex"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/conix/config"
	"github.com/ibm-messaging/mq-golang/ibmmq"
)

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~ shared by producer/consumer ~~~ shared by producer/consumer ~~~ shared
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func disco(qMgr ibmmq.MQQueueManager) error {
	err := qMgr.Disc()
	if err != nil {
		fmt.Printf("\n+++ Error during queue-manager-disconnect: %+v:", err)
	}
	return err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func close(object ibmmq.MQObject) error {
	err := object.Close(0)
	if err != nil {
		fmt.Printf("\n+++ Error during queue-object-close: %+v:", err)
	}
	return err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func getQMgr(iConfig config.ConfigStructur, iProgname string) (ibmmq.MQQueueManager, error) {
	var qMgr ibmmq.MQQueueManager
	var err error
	// ------------------------------------------------------------------------
	// Allocate the MQCNO and MQCD structures needed for the CONNX call.
	cno := ibmmq.NewMQCNO()
	cd := ibmmq.NewMQCD()
	// Fill in required fields in the MQCD channel definition structure
	cd.ChannelName = iConfig.ChannelName
	cd.ConnectionName = iConfig.Hostname + "(" + strconv.Itoa(iConfig.PortNumber) + ")"
	// Reference the CD:indicate we definitely use the client connection method
	cno.ClientConn = cd
	cno.Options = ibmmq.MQCNO_CLIENT_BINDING
	// MQ V9.1.2 allows apps to specify their names...ignored by older version
	cno.ApplName = "Golang " + iProgname
	// ------------------------------------------------------------------------
	csp := ibmmq.NewMQCSP()
	csp.AuthenticationType = ibmmq.MQCSP_AUTH_USER_ID_AND_PWD
	csp.UserId = iConfig.UserName
	csp.Password = iConfig.Password
	// Make the CNO refer to the CSP structure so it gets used during the connection
	cno.SecurityParms = csp
	// And now we can try to connect. Wait a short time before disconnecting.

	// ------------------------------------------------------------------------
	// This is where we connect to the queue manager
	qMgr, err = ibmmq.Connx(iConfig.ManagerName, cno)
	return qMgr, err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~ producer ~~~ producer ~~~ producer ~~~ producer ~~~ producer ~~~ produce
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func getProduceObj(iConfig config.ConfigStructur, iPtrQMgr *ibmmq.MQQueueManager) (ibmmq.MQObject, error) {
	var qObj ibmmq.MQObject
	var err error
	// Open the queue
	// Create the Object Descriptor that allows us to give the queue name
	mqod := ibmmq.NewMQOD()
	// We have to say how we are going to use this queue. In this case, to PUT
	// messages. That is done in the openOptions parameter.
	openOptions := ibmmq.MQOO_OUTPUT
	// Opening a QUEUE (rather than a Topic or other object type) and give the name
	mqod.ObjectType = ibmmq.MQOT_Q
	mqod.ObjectName = iConfig.QueueName

	qObj, err = (*iPtrQMgr).Open(mqod, openOptions)
	return qObj, err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func produceMesg(iPtrQObj *ibmmq.MQObject, iMessage string) (string, error) {
	var err error
	// --------------------------------------------------------------------
	// Prepair the Message-Send
	// --------------------------------------------------------------------
	// The PUT requires control structures, the Message Descriptor (MQMD)
	// and Put Options (MQPMO). Create those with default values.
	putmqmd := ibmmq.NewMQMD()
	pmo := ibmmq.NewMQPMO()
	// The default options are OK, but it's always
	// a good idea to be explicit about transactional boundaries as
	// not all platforms behave the same way.
	pmo.Options = ibmmq.MQPMO_NO_SYNCPOINT
	// Tell MQ what the message body format is. In this case, a text string
	putmqmd.Format = ibmmq.MQFMT_STRING
	// The message is always sent as bytes, so has to be converted before the PUT.
	buffer := []byte(iMessage)
	// --------------------------------------------------------------------
	// Now put the message to the queue
	// --------------------------------------------------------------------
	err = (*iPtrQObj).Put(putmqmd, pmo, buffer)
	return hex.EncodeToString(putmqmd.MsgId), err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func produce(iConfig config.ConfigStructur, iProgname string, iMessage string) int {
	var qMgr ibmmq.MQQueueManager
	var qObj ibmmq.MQObject
	var err error
	var msgID string
	for {
		// --------------------------------------------------------------------
		// This is where we connect to the queue manager
		// --------------------------------------------------------------------
		qMgr, err = getQMgr(iConfig, iProgname)
		if err != nil {
			fmt.Printf("\n+++ Error on queue-manager-connect: %+v", err)
			break
		} else {
			defer disco(qMgr)
		}
		// --------------------------------------------------------------------
		// This is where we get an Queue-Object
		// --------------------------------------------------------------------
		qObj, err = getProduceObj(iConfig, &qMgr)
		if err != nil {
			fmt.Printf("\n+++ Error on queue-open: %+v", err)
			break
		} else {
			defer close(qObj)
		}
		// --------------------------------------------------------------------
		// This is where we put the Message to the Queue
		// --------------------------------------------------------------------
		msgID, err = produceMesg(&qObj, iMessage)
		if err != nil {
			fmt.Printf("\nError from queue-put-message: %+v", err)
		} else {
			fmt.Printf("\n-d- MesgID: %+v :___MesgTxt: %+v", msgID, iMessage)
		}
		break
	}
	// ------------------------------------------------------------------------
	// Exit with any return code extracted from the failing MQI call.
	// Deferred disconnect will happen after the return
	mqret := 0
	if err != nil {
		mqret = int((err.(*ibmmq.MQReturn)).MQCC)
	}
	return mqret
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~ consumer ~~~ consumer ~~~ consumer ~~~ consumer ~~~ consumer ~~~ consume
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func getConsumeObj(iConfig config.ConfigStructur, iPtrQMgr *ibmmq.MQQueueManager) (ibmmq.MQObject, error) {
	var qObj ibmmq.MQObject
	var err error
	// Open the queue
	// Create the Object Descriptor that allows us to give the queue name
	mqod := ibmmq.NewMQOD()
	// We have to say how we are going to use this queue. In this case, to GET
	// messages. That is done in the openOptions parameter.
	openOptions := ibmmq.MQOO_INPUT_EXCLUSIVE
	// Opening a QUEUE (rather than a Topic or other object type) and give the name
	mqod.ObjectType = ibmmq.MQOT_Q
	mqod.ObjectName = iConfig.QueueName

	qObj, err = (*iPtrQMgr).Open(mqod, openOptions)
	return qObj, err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// There are now two forms of the Get verb.
// The original Get() takes
// a buffer and returns the length of the message. The user can then
// use a slice operation to extract just the relevant data.
//
// The new GetSlice() returns the message data pre-sliced as an extra
// return value.
func consumeMesg2(iPtrQObj *ibmmq.MQObject, iMessageID string) (bool, int, string, error) {
	var err error
	proceed := true
	datalen := 0
	var buffer []byte
	// The GET requires control structures, the Message Descriptor (MQMD)
	// and Get Options (MQGMO). Create those with default values.
	getmqmd := ibmmq.NewMQMD()
	gmo := ibmmq.NewMQGMO()
	gmo.Options = ibmmq.MQGMO_NO_SYNCPOINT
	gmo.Options |= ibmmq.MQGMO_WAIT
	gmo.WaitInterval = 3 * 1000 // The WaitInterval is in milliseconds
	// If there is a MesgId? match it during the Get processing
	if iMessageID != "" {
		fmt.Printf("\n-i- Match on MesgID: %+v", iMessageID)
		gmo.MatchOptions = ibmmq.MQMO_MATCH_MSG_ID
		getmqmd.MsgId, _ = hex.DecodeString(iMessageID)
		proceed = false
	}
	buffer = make([]byte, 1024)
	datalen, err = (*iPtrQObj).Get(getmqmd, gmo, buffer)
	if err != nil {
		proceed = false
		fmt.Printf("\n+++ Error on queue-read-get: %+v", err)
		mqret := err.(*ibmmq.MQReturn)
		if mqret.MQRC == ibmmq.MQRC_NO_MSG_AVAILABLE {
			// If there's no message available, then I won't treat that as a real error as
			// it's an expected situation
			fmt.Printf("\n-w- Warning on queue-read-getSlice: %+v", err)
			err = nil
		} else {
			fmt.Printf("\n+++ Error on queue-read-getSlice: %+v", err)
		}
	}
	return proceed, datalen, strings.TrimSpace(string(buffer[:datalen])), err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func consumeMesg(iPtrQObj *ibmmq.MQObject, iMessageID string) (bool, int, string, error) {
	var err error
	proceed := true
	datalen := 0
	var buffer []byte
	// The GET requires control structures, the Message Descriptor (MQMD)
	// and Get Options (MQGMO). Create those with default values.
	getmqmd := ibmmq.NewMQMD()
	gmo := ibmmq.NewMQGMO()
	// The default options are OK, but it's always
	// a good idea to be explicit about transactional boundaries as
	// not all platforms behave the same way.
	gmo.Options = ibmmq.MQGMO_NO_SYNCPOINT
	// Set options to wait for a maximum of 3 seconds for any new message to arrive
	gmo.Options |= ibmmq.MQGMO_WAIT
	gmo.WaitInterval = 3 * 1000 // The WaitInterval is in milliseconds
	// If there is a MesgId? match it during the Get processing
	if iMessageID != "" {
		fmt.Printf("\n-i- Match on MesgID: %+v", iMessageID)
		gmo.MatchOptions = ibmmq.MQMO_MATCH_MSG_ID
		getmqmd.MsgId, _ = hex.DecodeString(iMessageID)
		// Will only try to get a single message with the MsgId as there should
		// never be more than one. So set the flag to not retry after the first attempt.
		proceed = false
	}
	// Create a buffer for the message data.
	// the make() operation is just allocating space - len(buffer)==0 initially.
	buffer = make([]byte, 0, 1024)

	// Now we can try to get the message. This operation returns
	// a buffer that can be used directly.
	buffer, datalen, err = (*iPtrQObj).GetSlice(getmqmd, gmo, buffer)

	if err != nil {
		proceed = false
		mqret := err.(*ibmmq.MQReturn)
		if mqret.MQRC == ibmmq.MQRC_NO_MSG_AVAILABLE {
			// If there's no message available,
			//  then I won't treat that as a real error as
			//  it's an expected situation
			fmt.Printf("\n-w- Warning on queue-read-getSlice: %+v", err)
			err = nil
		} else {
			fmt.Printf("\n+++ Error on queue-read-getSlice: %+v", err)
		}
		//		} else {
		//			// Assume the message is a printable string
		//			fmt.Printf("\n-d- MesgLen: %+v :___MesgTxt: %+v", datalen, strings.TrimSpace(string(buffer)))
	}
	return proceed, datalen, strings.TrimSpace(string(buffer[:datalen])), err
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func consume(iConfig config.ConfigStructur, iProgname string, iMessageID string, loopMode bool) int {
	var qMgr ibmmq.MQQueueManager
	var qObj ibmmq.MQObject
	var err error
	for {
		// --------------------------------------------------------------------
		// This is where we connect to the queue manager
		// --------------------------------------------------------------------
		qMgr, err = getQMgr(iConfig, iProgname)
		if err != nil {
			fmt.Printf("\n+++ Error on queue-manager-connect: %+v", err)
			break
		} else {
			defer disco(qMgr)
		}
		// --------------------------------------------------------------------
		// This is where we get an Queue-Object
		// --------------------------------------------------------------------
		qObj, err = getConsumeObj(iConfig, &qMgr)
		if err != nil {
			fmt.Printf("\n+++ Error on queue-open: %+v", err)
			break
		} else {
			defer close(qObj)
		}
		break
	}
	// --------------------------------------------------------------------
	// Now get the message from the queue
	// --------------------------------------------------------------------
	proceed := true
	datalen := 0
	buffer := ""
	for proceed && err == nil {
		proceed, datalen, buffer, err = consumeMesg(&qObj, iMessageID)
		if proceed {
			fmt.Printf("\n-d- MesgLen: %+v :___MesgTxt: %+v", datalen, strings.TrimSpace(string(buffer[:datalen])))
		} else {
			fmt.Printf("\n-i- No more data found")
		}
		if !loopMode {
			break
		}
	}
	// ------------------------------------------------------------------------
	// Exit with any return code extracted from the failing MQI call.
	// Deferred disconnect will happen after the return
	mqret := 0
	if err != nil {
		mqret = int((err.(*ibmmq.MQReturn)).MQCC)
	}
	return mqret
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~ helper ~~~ helper ~~~ helper ~~~ helper ~~~ helper ~~~ helper ~~~ helper
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func formattedTime() string {
	return time.Now().Format(time.RFC3339)
}
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ~~~ main ~~~ main ~~~ main ~~~ main ~~~ main ~~~ main ~~~ main ~~~ main ~~~
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func main() {
	myName := os.Args[0]
	myCount := 0
	limit := 0
	delay := 0
	verbose := false
	modeProduce := true
	modeConsume := false
	modeBrowse := false
	loopMode := false
	configFile := "queue.config.json"
	message := fmt.Sprintf("Message-%.05d from %s at %s, delay:%d Sec(s)", myCount, myName, formattedTime(), delay)
	messageID := ""

	// It seem's like it is not possible to use MQGMO_BROWSE_FIRST, MQGMO_BROWSE_NEXT
	// flag.BoolVar(&modeBrowse, "browse", modeBrowse, "Change processing mode to browse (default:produce)")
	flag.BoolVar(&modeConsume, "consume", modeConsume, "Change processing mode to consume (default:produce)")
	flag.BoolVar(&loopMode, "loop", loopMode, "On mode CONSUME:Loop to all Messages, On Mode PRODUCE: Create every n-Seconds new Messages")
	flag.BoolVar(&verbose, "verbose", verbose, "Verbose mode, display more messages/info")
	// flag.BoolVar(&verbose, "v", verbose, "shorthand of -verbose")
	flag.IntVar(&delay, "delay", delay, "Used on Mode PRODUCE with LOOP-Option: Time of delay in seconds")
	flag.IntVar(&limit, "limit", limit, "Used on Mode PRODUCE with LOOP-Option: Limit of Messages that are created (default unlimited)")
	flag.StringVar(&configFile, "config", configFile, "File- and folder-name of the config file to be used")
	// flag.StringVar(&configFile, "c", "configFile", "shorthand of -config")
	flag.StringVar(&messageID, "messageID", messageID, "Message-ID to be used to consume a dedicated message")
	flag.StringVar(&message, "message", message, "Message-Text to be send to the queue")
	flag.Parse()

	config, err := config.CreateConfigFactory(configFile)
	if err != nil {
		fmt.Printf("+++ Failure during read on config-file: %s\nError is %v", configFile, err)
		panic(err)
	}
	if verbose {
		fmt.Printf("\n-i- Config: %+v", config)
	}
	// --- adjust arguments ---------------------------------------------------
	if modeBrowse || modeConsume {
		modeProduce = false
	}
	if modeBrowse && modeConsume {
		fmt.Printf("\n-w- Ignoring arg \"browse\" as \"consume\" is defined")
		modeBrowse = false
	}
	if modeProduce && limit > 0 {
		fmt.Printf("\n-i- Activating arg \"loop\" as \"limit\" is defined")
		loopMode = true
	}
	// --- processing ---------------------------------------------------------
	// if modeBrowse {
	// 	browse(config, myName, messageID, loopMode)
	// }
	if modeConsume {
		consume(config, myName, messageID, loopMode)
	}
	if modeProduce {
		if loopMode {
			for {
				myCount++
				message = fmt.Sprintf("Message-%.05d from %s at %s, delay:%d Sec(s)", myCount, myName, formattedTime(), delay)
				produce(config, myName, message)
				time.Sleep(time.Duration(delay) * time.Second)
				if limit > 0 {
					if limit <= myCount {
						break
					}
				}
			}
		} else {
			_ = produce(config, myName, message)
		}
	}
	if verbose {
		fmt.Printf("\n-i- done\n")
	} else {
		fmt.Println("")
	}
}
