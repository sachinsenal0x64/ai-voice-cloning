import asyncio
import json
from threading import Thread

from websockets.server import serve

from utils import generate, get_autoregressive_models, get_voice_list


# this is a not so nice workaround to set values to None if their string value is "None"
def replaceNoneStringWithNone(message):
    for member in message:
        if message[member] == 'None':
            message[member] = None

    return message


async def _handle_generate(websocket, message):
    message['result'] = generate(**message)
    await websocket.send(json.dumps(replaceNoneStringWithNone(message)))


async def _handle_get_autoregressive_models(websocket, message):
    message['result'] = get_autoregressive_models()
    await websocket.send(json.dumps(replaceNoneStringWithNone(message)))


async def _handle_get_voice_list(websocket, message):
    message['result'] = get_voice_list()
    await websocket.send(json.dumps(replaceNoneStringWithNone(message)))


async def _handle_message(websocket, message):
    message = replaceNoneStringWithNone(message)

    if message.get('action') and message['action'] == 'generate':
        await _handle_generate(websocket, message)
    elif message.get('action') and message['action'] == 'get_voices':
        await _handle_get_voice_list(websocket, message)
    elif message.get('action') and message['action'] == 'get_autoregressive_models':
        await _handle_get_autoregressive_models(websocket, message)
    else:
        print("websocket: undhandled message: " + message)


async def _handle_connection(websocket, path):
    print("websocket: client connected")

    async for message in websocket:
        try:
            await _handle_message(websocket, json.loads(message))
        except ValueError:
            print("websocket: malformed json received")


async def _run(host: str, port: int):
    print("websocket: server started")

    async with serve(_handle_connection, host, port, ping_interval=None):
        await asyncio.Future()  # run forever


def _run_server(listen_address: str, port: int):
    asyncio.run(_run(host=listen_address, port=port))


def start_websocket_server(listen_address: str, port: int):
    Thread(target=_run_server, args=[listen_address, port], daemon=True).start()
