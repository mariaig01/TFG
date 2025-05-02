from flask_socketio import join_room, emit
from extensions import socketio

@socketio.on('connect')
def on_connect():
    print('Usuario conectado vía Socket.IO')

@socketio.on('disconnect')
def on_disconnect():
    print('Usuario desconectado')

@socketio.on('join')
def on_join(data):
    user_id = str(data['user_id'])
    join_room(user_id)
    print(f'Usuario {user_id} se unió a su sala')

@socketio.on('mensaje_directo')
def on_mensaje_directo(data):
    receptor_id = str(data['id_receptor'])
    emit('nuevo_mensaje', data, to=receptor_id)
    print(f' Emitiendo mensaje a usuario {receptor_id}')

@socketio.on('join_group')
def on_join_group(data):
    group_id = f'grupo_{data["grupo_id"]}'
    join_room(group_id)
    print(f'Usuario se unió a grupo {group_id}')


@socketio.on('mensaje_grupo')
def on_mensaje_grupo(data):
    grupo_id = f'grupo_{data["grupo_id"]}'
    emit('nuevo_mensaje_grupo', data, to=grupo_id)
    print(f'Emitiendo mensaje al grupo {grupo_id}')
