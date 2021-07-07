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
	constructor(json) {
	}
}
