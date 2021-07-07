class Display {
	id() {
		return undefined;
	}
	node() {
		return document.getElementById(this.id())
	}
	html() {
		let div = document.createElement("div")
		div.id = this.id()
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
		this.url = json.URL
		this.is_favorite = json.is_favorite
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

	id() {
		return this.url
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

	constructor(json) {
		this.percentage = json.percentage
		this.charging = json.charging
	}

	id() {
		return 'battery'
	}

	html() {
	}
}
