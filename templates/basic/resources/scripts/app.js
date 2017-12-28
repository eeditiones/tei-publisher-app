$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    var appRoot = $("html").data("app");
    var tableOfContents = false;

    function resize() {
        if (document.getElementById("image-container")) {
            $("#document-pane").each(function() {
                var wh = $(window).height();
                var ot = $(this).offset().top;
                $(this).height(wh - ot);
                $("#image-container").height(wh - ot);
            });
        }
    }

    function getFontSize() {
        var size = $("#document-wrapper").css("font-size");
        return parseInt(size.replace(/^(\d+)px/, "$1"));
    }

    function load(params, direction) {
        var animOut = direction == "nav-next" ? "fadeOutLeft" : (direction == "nav-prev" ? "fadeOutRight" : "fadeOut");
        var animIn = direction == "nav-next" ? "fadeInRight" : (direction == "nav-prev" ? "fadeInLeft" : "fadeIn");
        var container = $("#document-pane");
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
            viewport: "#document-pane",
            content: function() {
                var fn = document.getElementById(this.hash.substring(1));
                return $(fn).find(".fn-content").html();
            }
        });
        $("#document-pane .note, .content .fn-back").click(function(ev) {
            ev.preventDefault();
            var fn = document.getElementById(this.hash.substring(1));
            fn.scrollIntoView();
        });
        $(".content .alternate").each(function() {
            $(this).popover({
                content: $(this).find(".altcontent").html(),
                trigger: "hover",
                html: true,
                container: "#document-wrapper"
            });
        });
        $("#document-pane img.facs").each(function(ev) {
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
        $("#document-pane").addClass("animated " + animIn).one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
            $(this).removeClass("animated " + animIn);
            if (id) {
                var target = document.getElementById(id.substring(1));
                target && target.scrollIntoView();
            }
        });
    }

    function isMobile() {
        var check = false;
        (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
        return check;
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
        ev && ev.preventDefault();
        // var relPath = this.pathname.replace(/^.*?\/([^\/]+)$/, "$1");
        var relPath = $(this).attr("data-doc");
        var url = "doc=" + relPath + "&" + this.search.substring(1);
        if (historySupport) {
            history.pushState({
                path: relPath
            }, "Navigate page", this.href.replace(/^.*?\/([^\/]+)$/, "$1"));
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
        $("#document-wrapper").css("font-size", (size + 1) + "px");
    });
    $("#zoom-out").click(function(ev) {
        ev.preventDefault();
        var size = getFontSize();
        $("#document-wrapper").css("font-size", (size - 1) + "px");
    });

    $(window).on("popstate", function(ev) {
        var state = ev.originalEvent.state;
        if (state) {
            var doc = state.path;
            var url = "doc=" + doc + "&" + window.location.search.substring(1) +
                window.location.hash;
            load(url);
        } else {
            window.location.reload();
        }
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
        $("#document-pane").swipe({
            swipe: function(event, direction, distance, duration, fingerCount, fingerData) {
                var nav;
                if (direction === "left") {
                    nav = $(".nav-next").get(0);
                } else if (direction === "right") {
                    nav = $(".nav-prev").get(0);
                } else {
                    return;
                }
                initLinks.apply(nav);
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

    $('#lang-select').on('change', function(ev) {
        var loc = window.location;
        var lang = $(this).val();
        var search;
        if (loc.search) {
            search = loc.search.replace(/\&?lang=[\w]+/, '');
            if (search == '?') {
                search = search + 'lang=' + lang;
            } else {
                search = search + '&lang=' + lang;
            }
        } else {
            search = '?lang=' + lang;
        }
        loc.replace(loc.protocol + '//' + loc.hostname + ':' + loc.port + loc.pathname + search + loc.hash);
    });
});

$(window).load(function () {
    if ($("#main-wrapper").length == 0) {
        return;
    }
    /*
     * Scroll the window to move anchor targets with hash under the topnav bar
     * https://github.com/twitter/bootstrap/issues/1768
     */
    var offset = $("#main-wrapper").offset().top;
    var shiftWindow = function() {
        scrollBy(0, -offset)
    };
    if (location.hash) {
        setTimeout(shiftWindow, 1);
    }
    window.addEventListener("hashchange", shiftWindow);
});
