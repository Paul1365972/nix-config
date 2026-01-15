(function () {
    if (!window.location.pathname.endsWith("/") && null == window.location.pathname.match("\\.")) {
        window.location.replace(window.location + ".html")
    }

    window.onload = function () {
        const anchors = document.getElementsByTagName("a");
        for (let i = 0; i < anchors.length; i++) {
            let href = anchors[i].getAttribute("href");

            if (href.startsWith("./wiki_edit/")) {
                path = href.slice(12).replace(".md", "");
                href = "https://github.com/vic/den/wiki/"+path+"/_edit";
                anchors[i].href = href + ".html";
                continue;
            }

            if (href.startsWith("./") && !href.endsWith(".html")) {
                anchors[i].href = href + ".html";
                continue;
            }

            if (href.startsWith("modules/") || href.startsWith("templates/") || href.startsWith("nix/")) {
                anchors[i].href = "https://github.com/vic/den/tree/main/" + href;
                continue;
            }
        }
    }
})();