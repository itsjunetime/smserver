class Display {
	id = undefined
	node() {
		return document.getElementById(this.id)
	}
	html() {
		let div = document.createElement("div")
		div.id = this.id
		return div
	}
	newDiv(cls = '') {
		let div = document.createElement('div')
		if (cls)
			div.className = cls;
		return div
	}
	newSpan(cls = '') {
		let div = document.createElement('span')
		if (cls)
			div.className = cls;
		return div
	}
	elem(a = '') {
		return document.createElement(a)
	}
}

class Photo extends Display {
	url; // string
	is_favorite;  // bool

	constructor(json) {
		super()
		this.url = json.URL
		this.is_favorite = json.is_favorite
		this.id = this.url
	}

	html() {
		let classes = `photo${this.is_favorite ? ' is_favorite' : ''}`
		let photo = this.newSpan(classes)
		photo.id = this.url

		photo.setAttribute('onclick', `photos.find(p => p.url == '${this.url}').select()`)
		photo.setAttribute('width', '160')
		photo.setAttribute('height', '160')
		photo.innerHTML = `<img src="${prefix}data?photo=${this.url}">`

		if (this.is_favorite) {
			let h = this.newSpan('favoriteHeart')
			h.innerHTML = '<i class="fas fa-heart"></i>'
			photo.appendChild(h)
		}

		return photo
	}

	select(sel = true) {
		let node = this.node()
		if (!node) return;

		if (sel && !node.className.includes('selectedPhoto'))
			node.className += ' selectedPhoto';
		else if (!sel && node.className.includes('selectedPhoto'))
			node.className = node.className.replace(/selectedPhoto/g, '');
	}
}

class BatteryStatus extends Display {
	percentage; // double
	charging; // bool

	perc_ids = ['empty', 'quarter', 'half', 'three-quarters', 'full']

	constructor(json) {
		super()
		this.percentage = json.percentage
		this.charging = json.charging
		this.id = 'battery'
	}

	html() {
		let cls = 'low'
		if (this.percentage > 20)
			cls = this.percentage > 35 ? 'fullEnough' : 'risky'

		let self = this.newDiv(cls)
		self.id = this.id

		let rounded = Math.min(~~(this.percentage / 25) + 1, 4)
		let perc_str = this.perc_ids[rounded]
		let rounded_perc = ~~Number(this.percentage)

		self.innerHTML = `
			${rounded_perc}%
			<span id="batterySymbol">
				${this.charging ? '<i id="chargingSymbol" class="fas fa-bolt"></i>' : ''}
				<i id="levelSymbol" class="fas fa-battery-${perc_str}"></i>
			</span>`;

		return self
	}

	refresh(perc, charg) {
		this.percentage = perc
		this.charging = charg

		let node = this.node()
		let html = this.html()
		if (!node)
			document.getElementById('stats').innerHTML = html.outerHTML
		else
			node.outerHTML = html.outerHTML
	}
}
