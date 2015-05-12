$(document).ready(function() {
    var historySupport = !!(window.history && window.history.pushState);
    
    $(".next,.previous").click(function(ev) {
        ev.preventDefault();
        var url = "doc=" + this.pathname.replace(/^.*\/([^/]+\/[^/]+)$/, "$1") + "&" + this.search.substring(1);
        if (historySupport) {
            history.pushState(null, null, this.href);
        }
        load(url, this.className);
    });
    
    $(window).on("popstate", function(ev) {
        var url = "doc=" + window.location.pathname.replace(/^.*\/([^/]+\/[^/]+)$/, "$1") + "&" + window.location.search.substring(1);
        load(url);
    });
});

function load(params, direction) {
    var animOut = direction == "next" ? "fadeOutLeft" : "fadeOutRight";
    var animIn = direction == "next" ? "fadeInRight" : "fadeInLeft";
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
                    $(".next").attr("href", data.next).css("visibility", "");
                } else {
                    $(".next").css("visibility", "hidden");
                }
                if (data.previous) {
                    $(".previous").attr("href", data.previous).css("visibility", "");
                } else {
                    $(".previous").css("visibility", "hidden");
                }
            });
    });
}