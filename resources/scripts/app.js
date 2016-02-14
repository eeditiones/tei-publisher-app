$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    var appRoot = $("html").data("app");

    function resize() {
        // var wh = ($(window).height()) / 2;
        // $(".page-nav").css("top", wh);
        // var tw = $(".toc").width();
        // $(".toc").css("max-width", tw);
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
            $.ajax({
                url: appRoot + "/modules/ajax.xql",
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
                    showContent(container, animIn, animOut);
                }
            });
        });
    }

    function initContent() {
        $(".content .note").popover({
            html: true,
            trigger: "hover"
        });
        $(".content .sourcecode").highlight();
        $(".content .alternate").each(function() {
            $(this).popover({
                content: $(this).find(".altcontent").html(),
                trigger: "hover",
                html: true
            });
        });
    }

    function showContent(container, animIn, animOut, id) {
        if (!id) {
            window.scrollTo(0,0);
        }
        container.removeClass("animated " + animOut);
        $("#content-container").addClass("animated " + animIn).one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
            $(this).removeClass("animated " + animIn);
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
    
    resize();
    $(".page-nav,.toc-link").click(function(ev) {
        ev.preventDefault();

        var relPath = this.pathname.replace(new RegExp("^" + appRoot + "(.*)$"), "$1");
        var url = "doc=" + relPath + "&" + this.search.substring(1);
        if (historySupport) {
            history.pushState(null, null, this.href);
        }
        load(url, this.className.split(" ")[0]);
    });
    $(".toc .toc-link").click(function(ev) {
        $(".toc").offcanvas('hide');
    });
    
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
        var url = "doc=" + window.location.pathname.replace(new RegExp("^" + appRoot + "(.*)$"), "$1") + "&" + window.location.search.substring(1) +
            "&id=" + window.location.hash.substring(1);
        console.log("popstate: %s", url);
        load(url);
    }).on("resize", resize);

    $("#collapse-sidebar").click(function(ev) {
        $("#sidebar").toggleClass("hidden");
        if ($("#sidebar").is(":visible")) {
            $("#right-panel").removeClass("col-md-12").addClass("col-md-9 col-md-offset-3");
        } else {
            $("#right-panel").addClass("col-md-12").removeClass("col-md-9 col-md-offset-3");
        }
        resize();
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
                var url = "doc=" + nav.pathname.replace(/^.*\/([^/]+\/[^/]+)$/, "$1") + "&" + nav.search.substring(1);
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
            url: "modules/regenerate.xql" + $(this).attr("href"),
            dataType: "html",
            success: function(data) {
                $("#messageDialog .message").html(data).find(".eXide-open").click(eXide);
            },
            error: function(xhr, status) {
                $("#messageDialog .message").html(xhr.responseXML);
            }
        });
    });
    
    $(".download-link").click(function(ev) {
        $("#pdf-info").modal("show");
        var token = $(this).attr("data-token");
        console.log("token = %s", token);
        downloadCheck = window.setInterval(function() {
            var cookieValue = $.macaroon("simple.token");
            if (cookieValue == token) {
                window.clearInterval(downloadCheck);
                $.macaroon("simple.token", null);
                $("#pdf-info").modal("hide");
            }
        }, 100);
    });
    
    $(".eXide-open").click(eXide);
    
    initContent();
});
