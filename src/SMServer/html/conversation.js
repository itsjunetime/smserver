class Conversation extends Display {
	unread; // bool
	chat_identifier; // string
	pinned; // bool
	latest_text; // string
	display_name; // string
	time_marker; // int
	relative_time; // string
	addresses; // string
	is_group; // bool
	members; // Array<Handle>

	selected = false;

	constructor(json) {
		super()

		this.unread = json.has_unread
		this.chat_identifier = json.chat_identifier
		this.pinned = json.pinned
		this.latest_text = json.latest_text
		this.display_name = json.display_name
		this.time_marker = json.time_marker
		this.relative_time = json.relative_time
		this.addresses = json.addresses
		this.is_group = json.is_group
		this.members = json.members.map(h => new Handle(h))
	}

	id() {
		return this.chat_identifier;
	}

	html() {
		let b = document.createElement('button')
		b.id = this.id()
		b.setAttribute('addresses', this.addresses ? this.addresses : this.chat_identifier);

		let i = this.newSpan()

		let cimg = document.createElement('img')
		cimg.className = 'chatImage'
		cimg.src = `${prefix}data?chat_id=${this.chat_identifier}`
		cimg.setAttribute('onerror', 'javascript:setProfileImageAsText(this)')
		cimg.setAttribute('display_name', this.display_name ? this.display_name : this.chat_identifier)
		i.appendChild(cimg)

		let classes = (this.selected ? 'selected' : '' ) + (this.unread ? ' unread' : '')

		let n = this.newSpan('chatName')

		let sp = document.createElement('span')
		sp.textContent = !this.display_name ? this.chat_identifier : this.display_name
		n.appendChild(sp)

		if (!this.pinned) {
			b.appendChild(i)

			let nonpic = this.newDiv('chatNonpic')
			let top = this.newDiv('chatToprow')

			if (!this.is_group && !this.chat_identifier.includes("@") && !this.display_name)
				n.innerHTML += `<span class="displayChatIdentifier"> (${this.chat_identifier})</span>`

			top.appendChild(n)

			let d = this.newDiv('chatDate')
			d.textContent = this.relative_time
			top.appendChild(d)
			nonpic.appendChild(top)

			let t = this.newDiv('chatText')
			t.textContent = this.latest_text
			nonpic.appendChild(t)
			b.appendChild(nonpic)

			classes += ' listed'
		} else {
			let t = this.newDiv('chatTop')
			t.appendChild(i)

			if (this.unread) {
				let ct = this.newDiv('chatText')
				ct.textContent = this.latest_text

				t.appendChild(ct)
			}

			b.appendChild(t)
			b.appendChild(n)
			classes += ' pinned'
		}

		b.className = classes

		var gts = `getTexts('${this.chat_identifier}'${this.addresses ? `, '${this.addresses}'` : ''})`
		b.setAttribute('onclick', gts)

		return b
	}

	setSelected(sel) {
		this.selected = sel

		let node = this.node()

		if (!node)
			return

		if (!sel && node.className.includes('selected'))
			node.className = node.className.replace(/selected/g, '')
		else if (sel) {
			if (!node.className.includes('selected'))
				node.className += ' selected'
			if (node.className.includes('unread'))
				node.className = node.className.replace(/unread/g, '')

			if (this.pinned && this.unread) {
				node.getElementsByClassName('chatText')[0].outerHTML = ''
			}

			this.unread = false
		}
	}

	image() {
		return this.node().getElementsByTagName('img')[0]
	}
}

class Handle {
	display_name; // string
	chat_identifier; // string

	constructor(json) {
		this.display_name = json.display_name
		this.chat_identifier = json.chat_identifier
	}
}
