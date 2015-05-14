$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    
    resize();
    $(".page-nav,.toc-link").click(function(ev) {
        ev.preventDefault();
        var url = "doc=" + this.pathname.replace(/^.*\/([^/]+\/[^/]+)$/, "$1") + "&" + this.search.substring(1);
        if (historySupport) {
            history.pushState(null, null, this.href);
        }
        load(url, this.className.split(" ")[0]);
    });
    
    $(window).on("popstate", function(ev) {
        var url = "doc=" + window.location.pathname.replace(/^.*\/([^/]+\/[^/]+)$/, "$1") + "&" + window.location.search.substring(1);
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
});

function resize() {
    var wh = ($(window).height()) / 2;
    $(".page-nav").css("top", wh);
    $(".nav-prev").css("left", $("#content-inner").offset().left);
}

function load(params, direction) {
    var animOut = direction == "nav-next" ? "fadeOutLeft" : "fadeOutRight";
    var animIn = direction == "nav-next" ? "fadeInRight" : "fadeInLeft";
    $("#content-container").addClass("animated " + animOut)
        .one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
            var container = $(this);
            $.getJSON("../modules/ajax.xql", params, function(data) {
                $(".content").replaceWith(data.content);
                $(".content .note").popover({
                    html: true,
                    trigger: "hover"
                });
                $(".content .sourcecode").highlight();
                container.removeClass("animated " + animOut);
                $("#content-container").addClass("animated " + animIn).one("webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend", function() {
                    $(this).removeClass("animated " + animIn);
                });
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
            });
    });
}