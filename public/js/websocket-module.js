var currentUser, ele, websocket;

function init()
{
    webSocket();
}

function webSocket()
{
    websocket = new WebSocket(wsUri);
    websocket.onopen = function(evt) { onOpen(evt) };
    websocket.onclose = function(evt) { onClose(evt) };
    websocket.onmessage = function(evt) { onMessage(evt) };
    websocket.onerror = function(evt) { onError(evt) };
}

function onOpen(evt)
{
}

function onClose(evt)
{
}

function onMessage(evt)
{
    var data;

    try {
        data = JSON.parse(evt.data);
    } catch (SyntaxError) {
        log('SyntaxError');
        log(evt);
        return false;
    }
    if (data.status == 'refresh') {
        var msg = {
            'user': currentUser,
            'type':'page',
            'message':{
                'course': course,
                'module': module,
                'pagenr': pagenr
            }
        };
        sendmsg(msg);
    }
    if (currentUser == data.user) {
        ele = document.getElementById(data.type);
        if (data.type == 'page') {
            pagenr = Number(data.message.pagenr);
        }
        if (data.type == 'library') {
        }
        if (data.type == 'module') {
            module = data.message.module;
        }
        if (data.type == 'navbar') {
        }
        if (data.type == 'corpus') {
        }
        writeToScreen(data.message);
        update_progress();
    } else {
        currentUser = data.user;
    }
}

function onError(evt)
{
    log('ERROR: ' + evt.data);
}

function doSend(message)
{
    websocket.send(message);
}

function writeToScreen(message)
{
    ele.innerHTML = message.content;
}

window.onunload = function () {
    websocket.close();
};

function log(msg)
{
    console.log(msg);
}

function get_module()
{
    var message = {};
    message.user = currentUser;
    message.type ='module';
    message.message = {};
    sendmsg(message);
}

function get_page(nr)
{
    var message = {};
    message.user = currentUser;
    message.type ='page';
    message.message = {};
    message.message.course = course;
    message.message.module = module;
    pagenr = nr;
    message.message.pagenr = pagenr;
    sendmsg(message);
}

function get_prev_page()
{
    var nr = Number(pagenr) - 1;
    get_page(nr);
}

function get_next_page()
{
    var nr = Number(pagenr) + 1;
    get_page(nr);
}

function update_progress()
{
    var progress = 100 * Number(pagenr) / Number(pages);
    ele = document.getElementById("progress");

    var message = { 'content': "<div class=\"progress-bar progress-bar-info\" style=\"width: " + progress + "%\"></div>"};
    writeToScreen(message);
}


function get_corpus_data(id, corpus) {
    var form        = document.getElementById(id);
    var windowsize  = form['select_ws'].value;
    var token       = form['select_search_for'].value;
    var statist     = form['select_statistic'].value;
    var min_collo   = form['input_min_collocator'].value;
    var min_freq    = form['input_min_node'].value;
    var search      = form['input_search'].value;
    var message = {};
    message.user = currentUser;
    message.type = 'corpus';
    message.id   = id;
    message.message = {};
    message.message.course      = course;
    message.message.corpus      = corpus;
    message.message.windowsize  = windowsize;
    message.message.token       = token;
    message.message.min_collo   = min_collo;
    message.message.min_freq    = min_freq;
    message.message.stat        = statist;
    message.message.search      = search;
    sendmsg(message);
}

function sendmsg(message)
{
    // check websocket is open and if not reconnect
    if (websocket.readyState >= 2) {
        init();
    }
    message.sendtime = now();
    doSend(JSON.stringify(message));
}

function now()
{
    if (!Date.now) {
        Date.now = function() { return new Date().getTime(); };
    }
    return Date.now();
}

window.addEventListener("load", init, false);

// asset
function modal_toggle(id)
{
    $('#'+id).modal('toggle')
}

function modal_show(id)
{
    $('#'+id).modal('show') 
}

function modal_hide(id)
{
    $('#'+id).modal('hide') 
}
