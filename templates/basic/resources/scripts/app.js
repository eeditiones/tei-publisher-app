$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    var appRoot = $("html").data("app");
    var tableOfContents = false;

    function resize() {
        if (document.getElementById("image-container")) {
            $("#content-container").each(function() {
                var wh = $(window).height();
                var ot = $(this).offset().top;
                $(this).height(wh - ot);
                $("#image-container").height(wh - ot);
            });
        }
    }

    function getFontSize() {
        var size = $("#content-inner").css("font-size");
        return parseInt(size.replace(/^(\d+)px/, "$1"));
    }

    function load(params, direction) {
        var animOut = direction == "nav-next" ? "fadeOutLeft" : (direction == "nav-prev" ? "fadeOutRight" : "fadeOut");
        var animIn = direction == "nav-next" ? "fadeInRight" : (direction == "nav-prev" ? "fadeInLeft" : "fadeIn");
        var container = $("#content-container");
        container.addClass("animated " + animOut)
            .one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
            console.log("Loading %s", params);
            $("#image-container img").css("display", "none");
            $.ajax({
                url: appRoot + "/modules/lib/ajax.xql",
                dataType: "json",
                data: params,
                error: function(xhr, status) {
                    alert("Not found: " + params);
                    showContent(container, animIn, animOut);
                },
                success: function(data) {
                    if (data.error) {
                        alert(data.error);
                        showContent(container, animIn, animOut);
                        return;
                    }
                    $(".content").replaceWith(data.content);
                    initContent();
                    if (data.next) {
                        $(".nav-next").attr("href", data.next).css("visibility", "");
                    } else {
                        $(".nav-next").css("visibility", "hidden");
                    }
                    if (data.previous) {
                        $(".nav-prev").attr("href", data.previous).css("visibility", "");
                    } else {
                        $(".nav-prev").css("visibility", "hidden");
                    }
                    if (data.switchView) {
                        $("#switch-view").attr("href", data.switchView);
                    }
                    if (data.div) {
                        $("#toc .active").removeClass("active");
                        var active = $("#toc a[data-div='" + data.div + "']");
                        active.toggleClass("active");
                        active.parents(".collapse").collapse('show');
                    }
                    showContent(container, animIn, animOut);
                }
            });
        });
    }

    function initContent() {
        $(".content .note").popover({
            html: true,
            trigger: "hover",
            placement: "auto bottom",
            viewport: "#content-container",
            content: function() {
                var fn = document.getElementById(this.hash.substring(1));
                return $(fn).find(".fn-content").html();
            }
        });
        $("#content-container .note, .content .fn-back").click(function(ev) {
            ev.preventDefault();
            var fn = document.getElementById(this.hash.substring(1));
            fn.scrollIntoView();
        });
        $(".content .sourcecode").highlight();
        $(".content .alternate").each(function() {
            $(this).popover({
                content: $(this).find(".altcontent").html(),
                trigger: "hover",
                html: true,
                container: "#content-inner"
            });
        });
        $("#content-container img.facs").each(function(ev) {
            $("#image-container .loading").show();
            var downloadingImage = new Image();
            $(downloadingImage).load(function() {
                $("#facsimile").attr("src", downloadingImage.src);
                $("#image-container .loading").hide();
                $("#image-container img").css("display", "");
            });
            downloadingImage.src = $(this).attr("src");
            $(this).remove();
        });
    }

    function showContent(container, animIn, animOut, id) {
        if (!id) {
            window.scrollTo(0,0);
        }
        container.removeClass("animated " + animOut);
        $("#content-container").addClass("animated " + animIn).one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
            $(this).removeClass("animated " + animIn);
            if (id) {
                var target = document.getElementById(id.substring(1));
                target && target.scrollIntoView();
            }
        });
    }

    function isMobile() {
      try{ document.createEvent("TouchEvent"); return true; }
      catch(e){ return false; }
    }

    function eXide(ev) {
        // try to retrieve existing eXide window
        var exide = window.open("", "eXide");
        if (exide && !exide.closed) {
            var snip = $(this).data("exide-create");
            var path = $(this).data("exide-open");
            var line = $(this).data("exide-line");

            // check if eXide is really available or it's an empty page
            var app = exide.eXide;
            if (app) {
                // eXide is there
                if (snip) {
                    exide.eXide.app.newDocument(snip, "xquery");
                } else {
                    exide.eXide.app.findDocument(path, line);
                }
                exide.focus();
                setTimeout(function() {
                    if ($.browser.msie ||
                        (typeof exide.eXide.app.hasFocus == "function" && !exide.eXide.app.hasFocus())) {
                        alert("Opened code in existing eXide window.");
                    }
                }, 200);
            } else {
                window.eXide_onload = function() {
                    console.log("onloaed called");
                    if (snip) {
                        exide.eXide.app.newDocument(snip, "xquery");
                    } else {
                        exide.eXide.app.findDocument(path);
                    }
                };
                // empty page
                exide.location = this.href.substring(0, this.href.indexOf('?'));
            }
            return false;
        }
        return true;
    }

    function initLinks(ev) {
        ev.preventDefault();
        // var relPath = this.pathname.replace(/^.*?\/([^\/]+)$/, "$1");
        var relPath = $(this).attr("data-doc");
        var url = "doc=" + relPath + "&" + this.search.substring(1);
        if (historySupport) {
            history.pushState(null, null, this.href.replace(/^.*?\/([^\/]+)$/, "$1"));
        }
        load(url, this.className.split(" ")[0]);
    }
    
    function tocLoaded() {
        $("#toc a[data-toggle='collapse']").click(function(ev) {
            var icon = $(this).find("span").text();
            $(this).find("span").text(icon == "expand_less" ? "expand_more" : "expand_less");
        });
        $(".toc-link").click(function(ev) {
            $("#sidebar").offcanvas('hide');
        });
        $(".toc-link").click(initLinks);
    }
    
    resize();
    $(".page-nav").click(initLinks);
    
    $("#zoom-in").click(function(ev) {
        ev.preventDefault();
        var size = getFontSize();
        $("#content-inner").css("font-size", (size + 1) + "px");
    });
    $("#zoom-out").click(function(ev) {
        ev.preventDefault();
        var size = getFontSize();
        $("#content-inner").css("font-size", (size - 1) + "px");
    });

    $(window).on("popstate", function(ev) {
        var doc = $(".nav-next").attr("data-doc") || $(".nav-prev").attr("data-doc");
        var url = "doc=" + doc + "&" + window.location.search.substring(1) +
            "&id=" + window.location.hash.substring(1);
        console.log("popstate: %s", url);
        load(url);
    }).on("resize", resize);

    $("#logout").on("click", function(ev) {
        ev.preventDefault();
        window.location.search = window.location.search + "&logout=true";
    });
    
    $(".toc-toggle").click( function(ev) {
        $("#toc-loading").each(function() {
            console.log("Loading toc...");
            var doc = $(".nav-next").attr("data-doc") || $(".nav-prev").attr("data-doc");
            $("#toc").load("templates/toc.html?doc=" +
                doc + "&" + window.location.search.substring(1),
                tocLoaded
            );
        });
    });

    if (isMobile()) {
        $("#content-container").swipe({
            swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
                var nav;
                if (direction === "left") {
                    nav = $(".nav-next").get(0);
                } else if (direction === "right") {
                    nav = $(".nav-prev").get(0);
                } else {
                    return;
                }
                var url = "doc=" + nav.pathname.replace(/^.*\/([^\/]+)$/, "$1") + "&" + nav.search.substring(1);
                if (historySupport) {
                    history.pushState(null, null, nav.href);
                }
                load(url, nav.className.split(" ")[0]);
            },
            allowPageScroll: "vertical"
        });
    }

    $(".recompile").click(function(ev) {
        ev.preventDefault();
        $("#messageDialog .message").html("Processing ...");
        $("#messageDialog").modal("show");
        $.ajax({
            url: appRoot + "/modules/lib/regenerate.xql" + $(this).attr("href"),
            dataType: "html",
            success: function(data) {
                $("#messageDialog .message").html(data).find(".eXide-open").click(eXide);
            },
            error: function(xhr, status) {
                $("#messageDialog .message").html(xhr.responseXML);
            }
        });
    });
    $("#reindex").click(function(ev) {
        ev.preventDefault();
        $("#messageDialog .message").html("Updating indexes ...");
        $("#messageDialog").modal("show");
        $.ajax({
            url: appRoot + "/modules/index.xql",
            dataType: "html",
            success: function(data) {
                $("#messageDialog .message").html(data);
            },
            error: function(xhr, status) {
                $("#messageDialog .message").html(xhr.responseXML);
            }
        });
    });

    $('.typeahead-meta').typeahead({
        items: 20,
        minLength: 4,
        source: function(query, callback) {
            var type = $("select[name='browse']").val() || "tei-text";
            $.getJSON("modules/autocomplete.xql?q=" + query + "&type=" + type, function(data) {
                callback(data || []);
            });
        },
        updater: function(item) {
            if (/[\s,]/.test(item)) {
                return '"' + item + '"';
            }
            return item;
        }
    });
    $('.typeahead-search').typeahead({
        items: 30,
        minLength: 4,
        source: function(query, callback) {
            var type = $("select[name='tei-target']").val() || "tei-text";
            var doc = $("#searchPageForm input[name='doc']").val();
            $.getJSON("modules/autocomplete.xql?q=" + query + "&type=" + type +
                "&doc=" + encodeURIComponent(doc), function(data) {
                callback(data || []);
            });
        }
    });

    $(".download-link").click(function(ev) {
        $("#pdf-info").modal("show");
        var token = $(this).attr("data-token");
        downloadCheck = window.setInterval(function() {
            var cookieValue = $.macaroon("simple.token");
            if (cookieValue == token) {
                window.clearInterval(downloadCheck);
                $.macaroon("simple.token", null);
                $("#pdf-info").modal("hide");
            }
        });
    });

    $(".eXide-open").click(eXide);

    initContent();
});
