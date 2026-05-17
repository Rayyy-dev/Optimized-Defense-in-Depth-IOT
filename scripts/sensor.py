import sys
import time
import random
import json
import paho.mqtt.client as mqtt

device_id = sys.argv[1]
sensor_type = sys.argv[2]
topic = f"iot/{sensor_type}/{device_id}"

client = mqtt.Client(client_id=device_id, callback_api_version=mqtt.CallbackAPIVersion.VERSION2)
client.connect("mqtt-broker", 1883, 60)

print(f"[{device_id}] started, publishing to {topic}")

while True:
    if sensor_type == "temperature":
        payload = {"device": device_id, "temp_c": round(random.uniform(18.0, 26.0), 2)}
    elif sensor_type == "motion":
        payload = {"device": device_id, "motion": random.choice([0, 0, 0, 1])}
    else:
        payload = {"device": device_id, "value": random.random()}
    
    client.publish(topic, json.dumps(payload))
    print(f"[{device_id}] published: {payload}")
    time.sleep(5)