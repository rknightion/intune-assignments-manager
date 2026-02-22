document$.subscribe(function () {
	// Update canonical URL on navigation
	var canonical = document.querySelector('link[rel="canonical"]');
	if (canonical) {
		canonical.href = window.location.href.split('?')[0].split('#')[0];
	}
});
