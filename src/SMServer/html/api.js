async function getTextFromURL(url) {
	if (debug) console.log(`getting text from url ${url}`);
	let return_text;
	let code = 200;
	await fetch(url).then((response) => {
		code = response.status;
		return code === 200 ? response.text() : response.statusText;
	})
	.then((response) => {
		return_text = response;
	})
	.catch(error => {
		if (!has_shown_warning)
			alert(`The server restarted, you need to reload and re-authenticate. url: ${url}`);
		has_shown_warning = true;
	});

	return [code, return_text];
}

async function fetchFromURL(url) {
	if (debug) console.log(`fetching url ${url}`);
	let ret;
	await fetch(url).then(response => {
		if (!response.ok) throw new Error(`HTTP error ${response.status}`);
		ret = response.json();
	})
	.catch(error => {
		if (!has_shown_warning)
			alert(`The server restarted, you need to reload and re-authenticate. url: ${url}`);
		has_shown_warning = true;
	});

	return ret;
}

async function getChats(offset = 0) {
	return fetchFromURL(`${prefix}requests?chats&chats_offset=${offset}`)
}

async function getMessages(chat_id, offset = 0, read_messages = null, num_messages = null) {
	let num = num_messages != null ? `&num_messages=${num_messages}` : ``
	let read = read_messages != null ? `&read_messages=${read_messages}` : ``
	let url = `${prefix}requests?messages=${chat_id}&messages_offset=${offset}${read}${num}`
	return fetchFromURL(url)
}

async function getConversation(chat_id) {
	return fetchFromURL(`${prefix}requests?conversation=${chat_id}`)
}

async function getPhotos(offset = 0) {
	return fetchFromURL(`${prefix}requests?photos&photos_offset=${offset}`)
}

async function getConfig() {
	return fetchFromURL(`${prefix}requests?config`)
}

async function deleteChat(chat_id) {
	return getTextFromURL(`${prefix}send?delete_chat=${chat_id}`)
}

async function deleteText(guid) {
	return getTextFromURL(`${prefix}send?delete_text=${guid}`)
}

async function sendTapback(tap, guid, remove) {
	return getTextFromURL(`${prefix}send?tapback=${tap}&tap_guid=${guid}&remove_tap=${remove}`)
}
