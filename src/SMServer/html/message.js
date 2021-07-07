class Message extends Display {
	ROWID; // int
	date; // int
	from_me; // bool
	imessage; // bool
	guid; // string
	subject; // string
	text; // string
	attachments; // Array<Attachment>
	has_attachments; // bool
	associated_message_type; // int
	associated_message_guid; // string
	balloon_bundle_id; // string
	date_read; // int

	group_action_type; // int
	item_type; // int
	item_description; // string

	chat_id; // string
	is_group; // bool
	sender; // string

	link_title; // string
	link_subtitle; // string
	link_type; // string

	tapbacks = []; // Array<Message>

	last = true;
	show_read = false;
	show_sender = false;
	showing_tapback = false;

	constructor(json) {
		super()

		this.ROWID = json.ROWID
		this.date = json.date
		this.from_me = json.is_from_me
		this.imessage = json.imessage
		this.guid = json.guid
		this.subject = json.subject
		this.text = json.text

		if (json.attachments)
			this.attachments = json.attachments.map(a => new Attachment(a))

		this.has_attachments = json.cache_has_attachments
		this.associated_message_type = json.associated_message_type
		this.associated_message_guid = json.associated_message_guid

		this.balloon_bundle_id = json.balloon_bundle_id
		this.date_read = json.date_read
		this.chat_id = json.chat_identifier ? json.chat_identifier : json.id
		this.is_group = json.is_group
		this.sender = json.sender

		this.group_action_type = json.group_action_type
		this.item_type = json.item_type
		this.item_description = json.item_description

		this.link_title = json.link_title
		this.link_subtitle = json.link_subtitle
		this.link_type = json.link_type
	}

	id() {
		return this.guid
	}

	html(show_sender = false, show_read = false) {
		this.show_sender = show_sender
		this.show_read = show_read

		/// if it's a group_action or item that we don't know how to handle and don't have a description for,
		/// just ignore it
		if ((this.group_action_type || this.item_type) && !this.item_description)
			return this.newSpan()
		else if (this.item_description) {
			/// but if we do have a description for it, show it
			let desc = this.newSpan('itemDescription')
			desc.innerHTML = `<p>${this.item_description}</p>`
			return desc
		}

		/// if it's not a tapback or tapback removal
		if (this.associated_message_type < 2000 || !this.associated_message_type) {
			let classes = `message ${this.from_me ? 'fromMe' : 'fromThem'} ${this.imessage ? 'iMessage' : 'SMS'}`

			if (show_sender)
				classes += ' withSender';
			if (show_read)
				classes += ' withReceipt';
			if (this.is_group && !this.from_me)
				classes += ' withImage';

			/// msg is the main body of all these messages
			let msg = this.newDiv(classes)
			msg.id = this.id()
			msg.setAttribute('title', timeConverter(this.date))
			msg.setAttribute('date_read', this.date_read)
			msg.setAttribute('date', this.date);

			/// show the sender if we're supposed to
			if (show_sender)
				msg.innerHTML += `<div class="sender">${this.sender}</div>`;

			/// show the profile image to the side if we're supposed to
			if (this.is_group && this.last && !this.from_me) {
				let img_sec = this.newSpan('profileImage')

				let img = this.elem('img')
				img.src = `${prefix}data?chat_id=${this.chat_id}`
				img.setAttribute('display_name', this.sender)
				img.setAttribute('onerror', 'javascript:setProfileImageAsText(this)')

				img_sec.appendChild(img)
				msg.appendChild(img_sec)
			}

			let main_msgs = this.newSpan('mainMessages')
			msg.appendChild(main_msgs)

			let rich_link = this.richLinkBubble()
			if (rich_link)
				main_msgs.appendChild(rich_link);

			if (this.balloon_bundle_id && !rich_link) {
				let text = this.textSegment('', 'p:0/')

				if (this.balloon_bundle_id == 'com.apple.DigitalTouchBalloonProvider')
					text.innerHTML = '<h3 style="margin: 4px;"><i class="fas fa-fingerprint"></i> &nbsp;Digital Touch Message</h3>';
				else if (this.balloon_bundle_id == 'com.apple.Handwriting.HandwritingProvider')
					text.innerHTML = '<h3 style="margin: 4px;"><i class="fas fa-paint-brush"></i> &nbsp;Handwritten Message</h3>';
				else
					text.innerHTML = '<h3 style="margin: 4px;">Unknown message</h3>';

				text.innerHTML += 'This cannot be viewed in SMServer. Please open it on your device.';

				main_msgs.appendChild(this.textAreaWithChild(text))
			} else if (!this.attachments) {

				let text_seg = this.textSegment('', 'p:0/')

				if (this.subject)
					text_seg.appendChild(this.subjectText())

				let body = this.newDiv()
				body.textContent = this.text
				text_seg.appendChild(body)

				main_msgs.appendChild(this.textAreaWithChild(text_seg))
			} else if (!rich_link) {
				if (this.subject) {
					let sub_seg = this.textSegment('', 'p:-1/')
					sub_seg.appendChild(this.subjectText())
					main_msgs.appendChild(this.textAreaWithChild(sub_seg))
				}

				for (let i = 0; i < this.attachments.length; i++)
					main_msgs.appendChild(this.attachment(i));

				if (this.text) {
					let text_seg = this.textSegment('', `p:${this.attachments.length}/`)

					let emoji_check = this.text.match(/\p{Extended_Pictographic}/gu)
					if (!this.subject && emoji_check && emoji_check.join('').length == this.text.length)
						text_seg.classList.add('allEmoji');

					text_seg.innerHTML = `<div>${this.text}</div>`
					main_msgs.appendChild(this.textAreaWithChild(text_seg))
				}
			}

			if (show_read)
				msg.innerHTML += `<span class="readReceipt"><span><strong>Read</strong>&nbsp;${timeConverter(this.date_read)}</span></span>`

			return msg
		} else {
			let orig = document.getElementById(this.associated_message_guid)

			if (!orig)
				return null;

			let elder = orig.parentNode

 			if (this.associated_message_type < 2006 && this.associated_message_type > 1999) {
				let tap = this.newSpan(`tapback ${this.from_me ? 'tapFromMe' : 'tapFromThem'}`)
				tap.setAttribute('tapbackType', String(this.associated_message_type - 2000))
				tap.setAttribute('sender', this.chat_id)

				tap.innerHTML = fa_icons[this.associated_message_type - 2000]

				let orig_tb = elder.querySelector(`[sender="${this.chat_id}"]`)

				if (orig_tb) {
					orig_tb.outerHTML = tap.outerHTML
				} else {
					let ln = elder.getElementsByClassName('tapback').length
					let mg = `${((ln + 1) * -17) + 5}px;`

					mg += `z-index: ${9 < (ln + 2) ? 9 : (ln + 2)};`
					if (elder.parentNode.parentNode.className.includes('fromThem')) {
						tap.setAttribute('style', `left:${mg}`)
						elder.appendChild(tap)
					} else {
						tap.setAttribute('style', `right:${mg}`)
						elder.insertBefore(tap, elder.firstChild)
					}
				}
			} else if (this.associated_message_type > 2999 && this.associated_message_type < 3006) {
				for (let i = 0; i < elder.children.length; i++) {
					if (Number(elder.children[i].getAttribute('tapbackType')) + 1000 == this.associated_message_type) {
						elder.children[i].outerHTML = ''
						break
					}
				}
			}
		}

		return this.newSpan()
	}

	textSegment(classes = "", prefix = "", last = true) {
		let sp = this.newSpan(`text ${this.last && last ? '' : 'notLast '}${classes}`)
		sp.setAttribute('onclick', `showTapbackDialog("${prefix}${this.guid}")`)
		sp.id = prefix + this.guid
		return sp
	}

	textAreaWithChild(child) {
		let sp = this.newSpan('textArea')
		sp.appendChild(child)
		return sp
	}

	attachment(idx) {
		let text = this.textSegment('', `p:${idx}/`, false)
		let file = this.attachments[idx].filename
		let mime = this.attachments[idx].mime_type

		let splits = mime.split('/')
		let bigType = splits[0]
		let smallType = splits[1]

		if (bigType == 'image')
			text.innerHTML = `<img src="${prefix}data?path=${file}"><br>`;
		else if (bigType == 'video')
			text.innerHTML = `<video controls src="${prefix}data?path=${file}" playsinline></video>`;
		else if (bigType == 'audio')
			text.innerHTML = `<audio controls="controls" src="${prefix}data?path=${file}"></audio>`;
		else if (file) {
			let fil_splits = file.split('/')
			let link = this.elem('a')
			link.href = `${prefix}data?path=${file.replace(/ /g, '%20')}`

			link.setAttribute('mime_type', mime)
			link.className = 'inlineAttachment'

			let fa = 'file'

			if (mime.length > 0 && smallType && mime_dict[smallType])
				fa = dict[smallType];

			let icon = `<i class="fas fa-${fa}"></i>`

			link.innerHTML = `${icon} <span>${fil_splits[fil_splits.length - 1]}</span>`
			text.innerHTML += link.outerHTML
		}

		if (bigType == 'image' || bigType == 'video' || bigType == 'audio')
			text.className += ' noPadding fullAttachment';

		return this.textAreaWithChild(text)
	}

	subjectText() {
		let sub = this.newDiv('subject')
		sub.textContent = this.subject
		return sub
	}

	richLinkBubble() {
		if (this.balloon_bundle_id != 'com.apple.messages.URLBalloonProvider' || !this.has_attachments)
			return null

		let main = this.textSegment('noPadding richLink', 'bp:')

		let img = this.elem('img')
		img.src = `${prefix}data?path=${this.attachments[this.attachments.length > 1 ? 1 : 0].filename}`

		let under = this.elem('a')
		under.href = (this.text.match(/^https?:\/\//) ? '' : 'http://') + this.text
		under.className = 'richLinkUnder'
		under.setAttribute('target', '_blank')
		under.setAttribute('rel', 'noreferrer noopener')

		if (this.attachments.length > 1) {
			main.appendChild(img)
			main.appendChild(this.elem('br'))
		} else {
			under.appendChild(img)
			under.classList.add('richLinkSmall')
		}

		let desc = this.newDiv('richLinkDescription')

		let title = this.newDiv('richLinkTitle')
		title.textContent = this.link_title
		desc.appendChild(title)

		if (this.attachments.length > 1) {
			let subtitle = this.newDiv('richLinkSubtitle')
			subtitle.textContent = this.link_subtitle
			desc.appendChild(subtitle)
		}

		under.appendChild(desc)

		if (this.link_type && this.link_type.split('.')[0] == 'music') {
			let icon = this.newDiv('richLinkIcon')

			let ii = this.elem('img')
			ii.src = `${prefix}data?path=${this.attachments[0].filename}`
			icon.appendChild(ii)
			under.appendChild(icon)
		}

		main.appendChild(under)
		return this.textAreaWithChild(main)
	}

	showTapbackDialog(guid) {
		let element = document.getElementById(`${guid}Tapback`)
		if (element) {
			element.outerHTML = ''
			return
		}

		let text = document.getElementById(guid)
		let classes = `text tapbackDialog ${this.from_me ? 'fromThem' : 'fromMe'} ${this.imessage ? 'iMessage' : 'SMS'}`
		let dialog = this.newSpan(classes)
		dialog.id = `${guid}Tapback`

		let my_tap = this.tapbacks.first(t => t.from_me)
		let sel = undefined
		if (my_tap)
			sel = my_tap.associated_message_type - 2000;

		fa_icons.forEach((idx, icon) => {
			let choice = this.newSpan(`tapbackChoice ${idx == sel ? 'tapbackChosen' : ''}`)
			choice.innerHTML = icon
			choice.setAttribute('onclick', `sendTapback("${guid}, ${idx}, "${current_chat_id}", ${idx == sel})`)
			dialog.appendChild(choice)
		})

		let trash = this.newSpan('tapbackChoice trashText')
		trash.innerHTML = '<i class="fas fa-trash-alt"></i>'
		trash.setAttribute('onclick', `deleteText("${guid}")`)
		dialog.appendChild(trash)

		document.getElementById('textContent').insertBefore(dialog, text.parentNode)
	}
}

class Attachment {
	filename;
	mime_type;

	constructor(json) {
		this.filename = json.filename
		this.mime_type = json.mime_type
	}
}
