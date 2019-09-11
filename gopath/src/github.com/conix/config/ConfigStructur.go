// Copyright (c) IBM Corporation 2019.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0, which is available at
// http://www.eclipse.org/legal/epl-2.0.
//
// SPDX-License-Identifier: EPL-2.0

// Implementation of the JMS style Golang interfaces to communicate with IBM MQ.
package config

// ConnectStructur defines a struct that contains attributes for
// each of the key properties required to establish a connection to an IBM MQ
// queue manager.
//
// The fields are defined as Public so that the struct can be initialised
// programmatically using whatever approach the application prefers.
type ConfigStructur struct {
	ManagerName string
	Hostname    string
	PortNumber  int
	ChannelName string
	UserName    string
	Password    string

	// New created by WVo
	QueueName string

	// TransportType int // Default to TransportType_CLIENT (0)

	// Equivalent to SSLCipherSpec and SSLClientAuth in the MQI client, however
	// the names have been updated here to reflect that SSL protocols have all
	// been discredited.
	// TLSCipherSpec string
	// TLSClientAuth string // Default to TLSClientAuth_NONE

	// KeyRepository    string
	// CertificateLabel string
}
