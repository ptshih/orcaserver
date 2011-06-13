<?php

// Put your device token here (without spaces):
$deviceToken = '1d2301b234494ed1df0b6bfc848840543b5fa45afec8f402a7b7a493b8195464'; // peter
// $deviceToken = 'db3511d0240f2873eecf366c998ba4aaf3d145691027045ca14e8e281faf2813'; // gene
// $deviceToken = 'b3ef602724f457b65e6c3bb553b326c55b6bd334c7be786ed38f970db6e3d0ea'; // tom
// Put your private key's passphrase here:
$passphrase = 'orca';

// Put your alert message here:
$message = 'The form of this phase of token trust ensures that only APNs generates the token which it will later honor, and it can assure itself that a token handed to it by a device.';

////////////////////////////////////////////////////////////////////////////////

$ctx = stream_context_create();
stream_context_set_option($ctx, 'ssl', 'local_cert', 'ck.pem');
stream_context_set_option($ctx, 'ssl', 'passphrase', $passphrase);

// Open a connection to the APNS server
$fp = stream_socket_client(
	'ssl://gateway.sandbox.push.apple.com:2195', $err,
	$errstr, 60, STREAM_CLIENT_CONNECT|STREAM_CLIENT_PERSISTENT, $ctx);

if (!$fp)
	exit("Failed to connect: $err $errstr" . PHP_EOL);

echo 'Connected to APNS' . PHP_EOL;

// Create the payload body
$body['aps'] = array(
	'alert' => $message,
	'sound' => 'default'
	);
	
$body['pod_id'] = "5242";
$body['from_id'] = "54848297";

// Encode the payload as JSON
$payload = json_encode($body);

// Build the binary notification
$msg = chr(0) . pack('n', 32) . pack('H*', $deviceToken) . pack('n', strlen($payload)) . $payload;

echo $msg;

// Send it to the server
$result = fwrite($fp, $msg, strlen($msg));

if (!$result)
	echo 'Message not delivered' . PHP_EOL;
else
	echo 'Message successfully delivered' . PHP_EOL;

// Close the connection to the server
fclose($fp);
