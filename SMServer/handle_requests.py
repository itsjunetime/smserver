import sqlite3

db_file = '/private/var/mobile/Library/SMS/sms.db'

def create_connection(db_file):
    conn = None
    try:
        conn = sqlite.connect(db_file)
    except Error as e:
        print(e)

    return conn

def get_texts_from_chat(conn, chat_id):
    if '@' in chat_id:
        chat_id.replace('@', '\@')
    cur = conn.cursor()
    new_tuple = (chat_id,)
    cur.execute('SELECT ROWID FROM chat WHERE chat_identifier=?', new_tuple)
    chat_id_tuple = cur.fetchone()
    cur.execute('SELECT message_id FROM chat_message_join WHERE chat_id=?', chat_id_tuple)
    message_id = cur.fetchall()
    messages = []
    for i in message_id:
        cur.execute('SELECT text, is_from_me FROM message WHERE ROWID=?', i)
        new_message = cur.fetchone()
        messages.append(new_message)
    return messages

c = create_connection(db_file)
b_messages = get_texts_from_chat(c, '+15203106053')

