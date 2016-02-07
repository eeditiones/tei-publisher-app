$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    var appRoot = $("html").data("app");

    function resize() {
        // var wh = ($(window).height()) / 2;
        // $(".page-nav").css("top", wh);
        // if ($("#sidebar").is(":visible")) {
        //     $(".nav-prev").css("left", $("#content-inner").offset().left);
        // }
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

    resize();
    $(".page-nav,.toc-link").click(function(ev) {
        ev.preventDefault();

        var relPath = this.pathname.replace(/^.*\/([^\/]+)$/, "$1");
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
        var url = "doc=" + window.location.pathname.replace(/^.*\/([^\/]+)$/, "$1") + "&" + window.location.search.substring(1) +
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
                var url = "doc=" + nav.pathname.replace(/^.*\/([^\/]+)$/, "$1") + "&" + nav.search.substring(1);
                if (historySupport) {
                    history.pushState(null, null, nav.href);
                }
                load(url, nav.className.split(" ")[0]);
            },
            allowPageScroll: "vertical"
        });
    }

    $("#recompile").click(function(ev) {
        ev.preventDefault();
        $("#messageDialog .message").html("Processing ...");
        $("#messageDialog").modal("show");
        $.ajax({
            url: appRoot + "/modules/regenerate.xql",
            dataType: "html",
            success: function(data) {
                $("#messageDialog .message").html(data);
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
            var type = $("select[name='browse']").val();
            $.getJSON("../modules/autocomplete.xql?q=" + query + "&type=" + type, function(data) {
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
            var type = $("select[name='tei-target']").val();
            $.getJSON("../modules/autocomplete.xql?q=" + query + "&type=" + type, function(data) {
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
    
    initContent();
});
