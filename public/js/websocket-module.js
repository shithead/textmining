var currentUser, ele, websocket;
var progress = 0.0;

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
    progress = 100 * Number(pagenr) / Number(pages);
    ele = document.getElementById("progress");

    var message = { 'content': "<div class=\"progress-bar progress-bar-info\" style=\"width: " + progress + "%\"></div>"};
    writeToScreen(message);
}

<xsl:text> Windowsize </xsl:text>
<select id="select_ws" class="form-control">
<xsl:apply-templates select="range">
<xsl:with-param name="end" select="5"/>
<xsl:with-param name="it" select="0"/>
<xsl:with-param name="id" select="'windowsize'"/>
<xsl:text> Word searching based on </xsl:text>
<div class="col-lg-3">
<select id="select_search_for" class="form-control">
<option value="wortforms" ><xsl:text>Word forms</xsl:text></option>
<option value="lemma" ><xsl:text>Lemma</xsl:text></option>
<option value="pos"   ><xsl:text>POS</xsl:text></option>
</select>
<xsl:text> min. frequency of searching word </xsl:text>
<input type="text" id="inputminnode" class="form-control"/>
<xsl:if test="frequence[@collocate='enable']">
<div class="form-group">
<label class="col-lg-3 control-label" for="select">
<xsl:text> min. frequency of collocate </xsl:text>
<input type="text" id="input_min_collocator" class="form-control"/>
</xsl:if>
<xsl:text> Signifikanzmaß </xsl:text>
<select id="selecti_statistic" class="form-control">
<xsl:if test="statistic/@chi">
<option value="chi2" ><xsl:text>Chi-Square</xsl:text></option>
</xsl:if>
<xsl:if test="statistic/@dice">
<option value="dice">
<xsl:text>Dice-Koeffizient (not supported) </xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@frequence">
<option value="frequence" >
<xsl:text>sort on frequency</xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@llr">
<option value="llr" >
<xsl:text>Log-Likelihood-Ratio (LLR)</xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@mi">
<option value="mi" >
<xsl:text>Mutual information (not supported) </xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@mi3">
<option value="mi3" >
<xsl:text>MI3 (not supported) </xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@tscore">
<option value="tscore" >
<xsl:text>T-Score (not supported) </xsl:text>
</option>
</xsl:if>
<xsl:if test="statistic/@zscore">
<option value="zscore" >
<xsl:text>Z-Score (not supported) </xsl:text>
</option>
</xsl:if>
</select>
</div>
</div>
<div class="form-group">
<label class="col-lg-3 control-label" for="select">
<xsl:text> search word (only one) </xsl:text>
</label>
<div class="col-lg-3">
<input type="text" id="inputDefault" class="form-control"/>
</div>
</div>
<div class="col-lg-10 col-lg-offset-2">
<div class="col-sm-4">
<button class="btn btn-primary" formaction="javascript:get_corpus_data()" type="submit">Submit</button>
</div>
<div class="col-sm-4">
<button class="btn btn-primary" type="reset">Reset</button>
</div>
</div>
</fieldset>
function get_corpus_data(
        corpus,
        windowsize,
        token,
        min-freq,
        statist,
        search
        ) {
    var message = {};
    message.user = currentUser;
    message.type = 'corpus';
    message.message = {};
    message.message.course      = course;
    message.message.corpus      = corpus;
    message.message.windowsize  = windowsize;
    message.message.token       = token;
    message.message.min_freq    = min-freq;
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
