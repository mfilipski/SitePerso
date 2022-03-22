function dv_rolloutManager(handlersDefsArray, baseHandler) {
    this.handle = function () {
        var errorsArr = [];

        var handler = chooseEvaluationHandler(handlersDefsArray);
        if (handler) {
            var errorObj = handleSpecificHandler(handler);
            if (errorObj === null) {
                return errorsArr;
            }
            else {
                var debugInfo = handler.onFailure();
                if (debugInfo) {
                    for (var key in debugInfo) {
                        if (debugInfo.hasOwnProperty(key)) {
                            if (debugInfo[key] !== undefined || debugInfo[key] !== null) {
                                errorObj[key] = encodeURIComponent(debugInfo[key]);
                            }
                        }
                    }
                }
                errorsArr.push(errorObj);
            }
        }

        var errorObjHandler = handleSpecificHandler(baseHandler);
        if (errorObjHandler) {
            errorObjHandler['dvp_isLostImp'] = 1;
            errorsArr.push(errorObjHandler);
        }
        return errorsArr;
    };

    function handleSpecificHandler(handler) {
        var request;
        var errorObj = null;

        try {
            request = handler.createRequest();
            if (request && !request.isSev1) {
                var url = request.url || request;
                if (url) {
                    if (!handler.sendRequest(url)) {
                        errorObj = createAndGetError('sendRequest failed.',
                            url,
                            handler.getVersion(),
                            handler.getVersionParamName(),
                            handler.dv_script);
                    }
                } else {
                    errorObj = createAndGetError('createRequest failed.',
                        url,
                        handler.getVersion(),
                        handler.getVersionParamName(),
                        handler.dv_script,
                        handler.dvScripts,
                        handler.dvStep,
                        handler.dvOther
                    );
                }
            }
        }
        catch (e) {
            errorObj = createAndGetError(e.name + ': ' + e.message, request ? (request.url || request) : null, handler.getVersion(), handler.getVersionParamName(), (handler ? handler.dv_script : null));
        }

        return errorObj;
    }

    function createAndGetError(error, url, ver, versionParamName, dv_script, dvScripts, dvStep, dvOther) {
        var errorObj = {};
        errorObj[versionParamName] = ver;
        errorObj['dvp_jsErrMsg'] = encodeURIComponent(error);
        if (dv_script && dv_script.parentElement && dv_script.parentElement.tagName && dv_script.parentElement.tagName == 'HEAD') {
            errorObj['dvp_isOnHead'] = '1';
        }
        if (url) {
            errorObj['dvp_jsErrUrl'] = url;
        }
        if (dvScripts) {
            var dvScriptsResult = '';
            for (var id in dvScripts) {
                if (dvScripts[id] && dvScripts[id].src) {
                    dvScriptsResult += encodeURIComponent(dvScripts[id].src) + ":" + dvScripts[id].isContain + ",";
                }
            }
            
            
            
        }
        return errorObj;
    }

    function chooseEvaluationHandler(handlersArray) {
        var config = window._dv_win.dv_config;
        var index = 0;
        var isEvaluationVersionChosen = false;
        if (config.handlerVersionSpecific) {
            for (var i = 0; i < handlersArray.length; i++) {
                if (handlersArray[i].handler.getVersion() == config.handlerVersionSpecific) {
                    isEvaluationVersionChosen = true;
                    index = i;
                    break;
                }
            }
        }
        else if (config.handlerVersionByTimeIntervalMinutes) {
            var date = config.handlerVersionByTimeInputDate || new Date();
            var hour = date.getUTCHours();
            var minutes = date.getUTCMinutes();
            index = Math.floor(((hour * 60) + minutes) / config.handlerVersionByTimeIntervalMinutes) % (handlersArray.length + 1);
            if (index != handlersArray.length) { 
                isEvaluationVersionChosen = true;
            }
        }
        else {
            var rand = config.handlerVersionRandom || (Math.random() * 100);
            for (var i = 0; i < handlersArray.length; i++) {
                if (rand >= handlersArray[i].minRate && rand < handlersArray[i].maxRate) {
                    isEvaluationVersionChosen = true;
                    index = i;
                    break;
                }
            }
        }

        if (isEvaluationVersionChosen == true && handlersArray[index].handler.isApplicable()) {
            return handlersArray[index].handler;
        }
        else {
            return null;
        }
    }
}

function dv_GetParam(url, name, checkFromStart) {
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
    var regexS = (checkFromStart ? "(?:\\?|&|^)" : "[\\?&]") + name + "=([^&#]*)";
    var regex = new RegExp(regexS);
    var results = regex.exec(url);
    if (results == null)
        return null;
    else
        return results[1];
}

function dv_SendErrorImp(serverUrl, errorsArr) {
    for (var j = 0; j < errorsArr.length; j++) {
        var errorQueryString = '';
        var errorObj = errorsArr[j];
        for (key in errorObj) {
            if (errorObj.hasOwnProperty(key)) {
                if (key.indexOf('dvp_jsErrUrl') == -1) {
                    errorQueryString += '&' + key + '=' + errorObj[key];
                }
                else {
                    var params = ['ctx', 'cmp', 'plc', 'sid'];
                    for (var i = 0; i < params.length; i++) {
                        var pvalue = dv_GetParam(errorObj[key], params[i]);
                        if (pvalue) {
                            errorQueryString += '&dvp_js' + params[i] + '=' + pvalue;
                        }
                    }
                }
            }
        }

        var windowProtocol = 'https:';
        var sslFlag = '&ssl=1';

        var errorImp = windowProtocol + '//' + serverUrl + sslFlag + errorQueryString;
        dv_sendRequest(errorImp);
    }
}

function dv_sendRequest(url) {
    document.write('<scr' + 'ipt language="javascript" src="' + url + '"></scr' + 'ipt>');
}

function dv_GetRnd() {
    return ((new Date()).getTime() + "" + Math.floor(Math.random() * 1000000)).substr(0, 16);
}

function doesBrowserSupportHTML5Push() {
    "use strict";
    return typeof window.parent.postMessage === 'function' && window.JSON;
}

function dvBsrType() {
    'use strict';
    var that = this;
    var eventsForDispatch = {};

    this.pubSub = new function () {

        var subscribers = [];

        this.subscribe = function (eventName, uid, actionName, func) {
            if (!subscribers[eventName + uid])
                subscribers[eventName + uid] = [];
            subscribers[eventName + uid].push({Func: func, ActionName: actionName});
        };

        this.publish = function (eventName, uid) {
            var actionsResults = [];
            if (eventName && uid && subscribers[eventName + uid] instanceof Array)
                for (var i = 0; i < subscribers[eventName + uid].length; i++) {
                    var funcObject = subscribers[eventName + uid][i];
                    if (funcObject && funcObject.Func && typeof funcObject.Func == "function" && funcObject.ActionName) {
                        var isSucceeded = runSafely(function () {
                            return funcObject.Func(uid);
                        });
                        actionsResults.push(encodeURIComponent(funcObject.ActionName) + '=' + (isSucceeded ? '1' : '0'));
                    }
                }
            return actionsResults.join('&');
        };
    };

    this.domUtilities = new function () {
        this.addImage = function (url, parentElement) {
            var image = parentElement.ownerDocument.createElement("img");
            image.width = 0;
            image.height = 0;
            image.style.display = 'none';
            image.src = appendCacheBuster(url);
            parentElement.insertBefore(image, parentElement.firstChild);
        };

        this.addScriptResource = function (url, parentElement) {
            var scriptElem = parentElement.ownerDocument.createElement("script");
            scriptElem.type = 'text/javascript';
            scriptElem.src = appendCacheBuster(url);
            parentElement.insertBefore(scriptElem, parentElement.firstChild);
        };

        this.addScriptCode = function (srcCode, parentElement) {
            var scriptElem = parentElement.ownerDocument.createElement("script");
            scriptElem.type = 'text/javascript';
            scriptElem.innerHTML = srcCode;
            parentElement.insertBefore(scriptElem, parentElement.firstChild);
        };

        this.addHtml = function (srcHtml, parentElement) {
            var divElem = parentElement.ownerDocument.createElement("div");
            divElem.style = "display: inline";
            divElem.innerHTML = srcHtml;
            parentElement.insertBefore(divElem, parentElement.firstChild);
        };
    };

    this.resolveMacros = function (str, tag) {
        var viewabilityData = tag.getViewabilityData();
        var viewabilityBuckets = viewabilityData && viewabilityData.buckets ? viewabilityData.buckets : {};
        var upperCaseObj = objectsToUpperCase(tag, viewabilityData, viewabilityBuckets);
        var newStr = str.replace('[DV_PROTOCOL]', upperCaseObj.DV_PROTOCOL);
        newStr = newStr.replace('[PROTOCOL]', upperCaseObj.PROTOCOL);
        newStr = newStr.replace(/\[(.*?)\]/g, function (match, p1) {
            var value = upperCaseObj[p1];
            if (value === undefined || value === null)
                value = '[' + p1 + ']';
            return encodeURIComponent(value);
        });
        return newStr;
    };

    this.settings = new function () {
    };

    this.tagsType = function () {
    };

    this.tagsPrototype = function () {
        this.add = function (tagKey, obj) {
            if (!that.tags[tagKey])
                that.tags[tagKey] = new that.tag();
            for (var key in obj)
                that.tags[tagKey][key] = obj[key];
        };
    };

    this.tagsType.prototype = new this.tagsPrototype();
    this.tagsType.prototype.constructor = this.tags;
    this.tags = new this.tagsType();

    this.tag = function () {
    };

    this.tagPrototype = function () {
        this.set = function (obj) {
            for (var key in obj)
                this[key] = obj[key];
        };

        this.getViewabilityData = function () {
        };
    };

    this.tag.prototype = new this.tagPrototype();
    this.tag.prototype.constructor = this.tag;

    this.getTagObjectByService = function (serviceName) {
        for (var impressionId in this.tags) {
            if (typeof this.tags[impressionId] === 'object'
                && this.tags[impressionId].services
                && this.tags[impressionId].services[serviceName]
                && !this.tags[impressionId].services[serviceName].isProcessed) {
                this.tags[impressionId].services[serviceName].isProcessed = true;
                return this.tags[impressionId];
            }
        }

        return null;
    };

    this.addService = function (impressionId, serviceName, paramsObject) {
        if (!impressionId || !serviceName)
            return;

        if (!this.tags[impressionId])
            return;
        else {
            if (!this.tags[impressionId].services)
                this.tags[impressionId].services = {};

            this.tags[impressionId].services[serviceName] = {
                params: paramsObject,
                isProcessed: false
            };
        }
    };

    this.Enums = {
        BrowserId: {Others: 0, IE: 1, Firefox: 2, Chrome: 3, Opera: 4, Safari: 5},
        TrafficScenario: {OnPage: 1, SameDomain: 2, CrossDomain: 128}
    };

    this.CommonData = {};

    var runSafely = function (action) {
        try {
            var ret = action();
            return ret !== undefined ? ret : true;
        } catch (e) {
            return false;
        }
    };

    var objectsToUpperCase = function () {
        var upperCaseObj = {};
        for (var i = 0; i < arguments.length; i++) {
            var obj = arguments[i];
            for (var key in obj) {
                if (obj.hasOwnProperty(key)) {
                    upperCaseObj[key.toUpperCase()] = obj[key];
                }
            }
        }
        return upperCaseObj;
    };

    var appendCacheBuster = function (url) {
        if (url !== undefined && url !== null && url.match("^http") == "http") {
            if (url.indexOf('?') !== -1) {
                if (url.slice(-1) == '&')
                    url += 'cbust=' + dv_GetRnd();
                else
                    url += '&cbust=' + dv_GetRnd();
            }
            else
                url += '?cbust=' + dv_GetRnd();
        }
        return url;
    };

    
    var messagesClass = function () {
        var waitingMessages = [];

        this.registerMsg = function(dvFrame, data) {
            if (!waitingMessages[dvFrame.$frmId]) {
                waitingMessages[dvFrame.$frmId] = [];
            }

            waitingMessages[dvFrame.$frmId].push(data);

            if (dvFrame.$uid) {
                sendWaitingEventsForFrame(dvFrame, dvFrame.$uid);
            }
        };

        this.startSendingEvents = function(dvFrame, impID) {
            sendWaitingEventsForFrame(dvFrame, impID);
            
        };

        function sendWaitingEventsForFrame(dvFrame, impID) {
            if (waitingMessages[dvFrame.$frmId]) {
                var eventObject = {};
                for (var i = 0; i < waitingMessages[dvFrame.$frmId].length; i++) {
                    var obj = waitingMessages[dvFrame.$frmId].pop();
                    for (var key in obj) {
                        if (typeof obj[key] !== 'function' && obj.hasOwnProperty(key)) {
                            eventObject[key] = obj[key];
                        }
                    }
                }
                that.registerEventCall(impID, eventObject);
            }
        }

        function startMessageManager() {
            for (var frm in waitingMessages) {
                if (frm && frm.$uid) {
                    sendWaitingEventsForFrame(frm, frm.$uid);
                }
            }
            setTimeout(startMessageManager, 10);
        }
    };
    this.messages = new messagesClass();

    this.dispatchRegisteredEventsFromAllTags = function () {
        for (var impressionId in this.tags) {
            if (typeof this.tags[impressionId] !== 'function' && typeof this.tags[impressionId] !== 'undefined')
                dispatchEventCalls(impressionId, this);
        }
    };

    var dispatchEventCalls = function (impressionId, dvObj) {
        var tag = dvObj.tags[impressionId];
        var eventObj = eventsForDispatch[impressionId];
        if (typeof eventObj !== 'undefined' && eventObj != null) {
            var url = tag.protocol + '//' + tag.ServerPublicDns + "/bsevent.gif?impid=" + impressionId + '&' + createQueryStringParams(eventObj);
            dvObj.domUtilities.addImage(url, tag.tagElement.parentElement);
            eventsForDispatch[impressionId] = null;
        }
    };

    this.registerEventCall = function (impressionId, eventObject, timeoutMs) {
        addEventCallForDispatch(impressionId, eventObject);

        if (typeof timeoutMs === 'undefined' || timeoutMs == 0 || isNaN(timeoutMs))
            dispatchEventCallsNow(this, impressionId, eventObject);
        else {
            if (timeoutMs > 2000)
                timeoutMs = 2000;

            var dvObj = this;
            setTimeout(function () {
                dispatchEventCalls(impressionId, dvObj);
            }, timeoutMs);
        }
    };

    var dispatchEventCallsNow = function (dvObj, impressionId, eventObject) {
        addEventCallForDispatch(impressionId, eventObject);
        dispatchEventCalls(impressionId, dvObj);
    };

    var addEventCallForDispatch = function (impressionId, eventObject) {
        for (var key in eventObject) {
            if (typeof eventObject[key] !== 'function' && eventObject.hasOwnProperty(key)) {
                if (!eventsForDispatch[impressionId])
                    eventsForDispatch[impressionId] = {};
                eventsForDispatch[impressionId][key] = eventObject[key];
            }
        }
    };

    if (window.addEventListener) {
        window.addEventListener('unload', function () {
            that.dispatchRegisteredEventsFromAllTags();
        }, false);
        window.addEventListener('beforeunload', function () {
            that.dispatchRegisteredEventsFromAllTags();
        }, false);
    }
    else if (window.attachEvent) {
        window.attachEvent('onunload', function () {
            that.dispatchRegisteredEventsFromAllTags();
        }, false);
        window.attachEvent('onbeforeunload', function () {
            that.dispatchRegisteredEventsFromAllTags();
        }, false);
    }
    else {
        window.document.body.onunload = function () {
            that.dispatchRegisteredEventsFromAllTags();
        };
        window.document.body.onbeforeunload = function () {
            that.dispatchRegisteredEventsFromAllTags();
        };
    }

    var createQueryStringParams = function (values) {
        var params = '';
        for (var key in values) {
            if (typeof values[key] !== 'function') {
                var value = encodeURIComponent(values[key]);
                if (params === '')
                    params += key + '=' + value;
                else
                    params += '&' + key + '=' + value;
            }
        }

        return params;
    };
}

function dv_baseHandler(){function x(b){try{var c=new URL(b);return!c.pathname||""==c.pathname||"/"==c.pathname}catch(d){}}function K(b){var c="http:",d=window._dv_win.location.toString().match("^http(?:s)?");"https"!=b.match("^https")||"https"!=d&&"http"==d||(c="https:");return c}function P(){var b="http:";"http:"!=window._dv_win.location.protocol&&(b="https:");return b}function Q(b){var c=window._dv_win.dvRecoveryObj;if(c){var d=dv_GetParam(b.dvparams,"ctx",!0);c=c[d]?c[d].RecoveryTagID:c._fallback_?
c._fallback_.RecoveryTagID:1;1===c&&b.tagsrc?document.write(b.tagsrc):2===c&&b.altsrc&&document.write(b.altsrc);return!0}return!1}function R(){var b=window._dv_win.dv_config&&window._dv_win.dv_config.isUT?window._dv_win.bsredirect5ScriptsInternal[window._dv_win.bsredirect5ScriptsInternal.length-1]:window._dv_win.bsredirect5ScriptsInternal.pop();window._dv_win.bsredirect5Processed.push(b);return b}function S(b){var c=window._dv_win.dv_config=window._dv_win.dv_config||{};c.cdnAddress=c.cdnAddress||
"cdn.doubleverify.com";return'<html><head><script type="text/javascript">('+function(){try{window.$dv=window.$dvbsr||parent.$dvbsr,window.$dv.dvObjType="dvbsr"}catch(d){}}.toString()+')();\x3c/script></head><body><script type="text/javascript">('+(b||"function() {}")+')("'+c.cdnAddress+'");\x3c/script><script type="text/javascript">setTimeout(function() {document.close();}, 0);\x3c/script></body></html>'}function L(b,c){var d=document.createElement("iframe");d.name=d.id="iframe_"+dv_GetRnd();d.width=
0;d.height=0;d.id=c;d.style.display="none";d.src=b;return d}function D(b,c,d){d=d||150;var e=window._dv_win||window;if(e.document&&e.document.body)return c&&c.parentNode?c.parentNode.insertBefore(b,c):e.document.body.insertBefore(b,e.document.body.firstChild),!0;if(0<d)setTimeout(function(){D(b,c,--d)},20);else return!1}function T(b){var c=null;try{if(c=b&&b.contentDocument)return c}catch(d){}try{if(c=b.contentWindow&&b.contentWindow.document)return c}catch(d){}try{if(c=window._dv_win.frames&&window._dv_win.frames[b.name]&&
window._dv_win.frames[b.name].document)return c}catch(d){}return null}function U(){function b(c){d++;var g=c.parent==c;return c.mraid||g?c.mraid:20>=d&&b(c.parent)}var c=window._dv_win||window,d=0;try{return b(c)}catch(e){}}function y(b,c,d,e,g,h,k,f,l){var r=window._dv_win.dv_config&&window._dv_win.dv_config.bst2tid?window._dv_win.dv_config.bst2tid:dv_GetRnd();var n=window.parent.postMessage&&window.JSON;var m=!0;var u=!1;if("0"==dv_GetParam(b.dvparams,"t2te")||window._dv_win.dv_config&&1==window._dv_win.dv_config.supressT2T)u=
!0;if(n&&0==u)try{u="https://cdn3.doubleverify.com/bst2tv3.html";window._dv_win&&window._dv_win.dv_config&&window._dv_win.dv_config.bst2turl&&(u=window._dv_win.dv_config.bst2turl);var p=L(u,"bst2t_"+r);m=D(p)}catch(z){}var v=(u=(/iPhone|iPad|iPod|\(Apple TV|iOS|Coremedia|CFNetwork\/.*Darwin/i.test(navigator.userAgent)||navigator.vendor&&"apple, inc."===navigator.vendor.toLowerCase())&&!window.MSStream)?"https:":K(k.src),M="0";"https:"==v&&(M="1");p=b.rand;var N="__verify_callback_"+p,x="__tagObject_callback_"+
p;V(N,b);W(x,k,b,u);void 0==b.dvregion&&(b.dvregion=0);var E="";p=k="";try{for(var F=d,G=0;10>G&&F!=window.top;)G++,F=F.parent;d.depth=G;dv_additionalUrl=X(d);k="&aUrl="+encodeURIComponent(dv_additionalUrl.url);p="&aUrlD="+dv_additionalUrl.depth;E=d.depth+e;g&&d.depth--}catch(z){p=k=E=d.depth=""}void 0!=b.aUrl&&(k="&aUrl="+b.aUrl);e=window._dv_win&&window._dv_win.dv_config&&window._dv_win.dv_config.verifyJSCURL?dvConfig.verifyJSCURL+"?":v+"//rtb"+b.dvregion+".doubleverify.com/verifyc.js?";a:{g=window._dv_win;
v=0;try{for(;10>v;){if(g.maple&&"object"===typeof g.maple){var H=!0;break a}if(g==g.parent){H=!1;break a}v++;g=g.parent}}catch(z){}H=!1}b=e+b.dvparams+"&num=5&srcurlD="+d.depth+"&callback="+N+"&jsTagObjCallback="+x+"&ssl="+M+(u?"&dvf=0":"")+(H?"&dvf=1":"")+"&refD="+E+"&htmlmsging="+(n?"1":"0")+"&guid="+r;c="dv_url="+encodeURIComponent(c);if(0==m||h)b=b+("&dvp_isBodyExistOnLoad="+(m?"1":"0"))+("&dvp_isOnHead="+(h?"1":"0"));U()&&(b+="&ismraid=1");f&&(b+="&dvp_sfr=1");l&&(b+="&dvp_sfe=1");if((h=window[I("=@42E:@?")][I("2?46DE@C~C:8:?D")])&&
0<h.length){f=[];f[0]=window.location.protocol+"//"+window.location.hostname;for(l=0;l<h.length;l++)f[l+1]=h[l];h=f.reverse().join(",")}else h=null;h&&(c+="&ancChain="+encodeURIComponent(h));h=4E3;/MSIE (\d+\.\d+);/.test(navigator.userAgent)&&7>=new Number(RegExp.$1)&&(h=2E3);k.length+p.length+b.length<=h&&(b+=p,c+=k);if(void 0!=window._dv_win.$dvbsr.CommonData.BrowserId&&void 0!=window._dv_win.$dvbsr.CommonData.BrowserVersion&&void 0!=window._dv_win.$dvbsr.CommonData.BrowserIdFromUserAgent)m=window._dv_win.$dvbsr.CommonData.BrowserId,
l=window._dv_win.$dvbsr.CommonData.BrowserVersion,f=window._dv_win.$dvbsr.CommonData.BrowserIdFromUserAgent;else{m=[{id:4,brRegex:"OPR|Opera",verRegex:"(OPR/|Version/)"},{id:1,brRegex:"MSIE|Trident/7.*rv:11|rv:11.*Trident/7|Edge/|Edg/",verRegex:"(MSIE |rv:| Edge/|Edg/)"},{id:2,brRegex:"Firefox",verRegex:"Firefox/"},{id:0,brRegex:"Mozilla.*Android.*AppleWebKit(?!.*Chrome.*)|Linux.*Android.*AppleWebKit.* Version/.*Chrome",verRegex:null},{id:0,brRegex:"AOL/.*AOLBuild/|AOLBuild/.*AOL/|Puffin|Maxthon|Valve|Silk|PLAYSTATION|PlayStation|Nintendo|wOSBrowser",
verRegex:null},{id:3,brRegex:"Chrome",verRegex:"Chrome/"},{id:5,brRegex:"Safari|(OS |OS X )[0-9].*AppleWebKit",verRegex:"Version/"}];f=0;l="";p=navigator.userAgent;for(k=0;k<m.length;k++)if(null!=p.match(new RegExp(m[k].brRegex))){f=m[k].id;if(null==m[k].verRegex)break;p=p.match(new RegExp(m[k].verRegex+"[0-9]*"));null!=p&&(l=p[0].match(new RegExp(m[k].verRegex)),l=p[0].replace(l[0],""));break}k=Y();4==f&&(k=f);m=k;l=k===f?l:"";window._dv_win.$dvbsr.CommonData.BrowserId=m;window._dv_win.$dvbsr.CommonData.BrowserVersion=
l;window._dv_win.$dvbsr.CommonData.BrowserIdFromUserAgent=f}b+="&brid="+m+"&brver="+l+"&bridua="+f;"prerender"===window._dv_win.document.visibilityState&&(b+="&prndr=1");(f=Z())&&(b+="&m1="+f);(f=aa())&&0<f.f&&(b+="&bsig="+f.f,b+="&usig="+f.s);try{var y=J();f=0;var A=y.document;y==window.top&&""==A.title&&!A.querySelector("meta[charset]")&&A.querySelector('div[style*="background-image: url("]')&&(A.querySelector('script[src*="j.pubcdn.net"]')||A.querySelector('span[class="ad-close"]'))&&(f+=Math.pow(2,
6));var B=f}catch(z){B=null}0<B&&(b+="&hdsig="+B);B=b;try{var w="&fcifrms="+window.top.length;window.history&&(w+="&brh="+window.history.length);var q=J(),C=q.document;if(q==window.top){w+="&fwc="+((q.FB?1:0)+(q.twttr?2:0)+(q.outbrain?4:0)+(q._taboola?8:0));try{C.cookie&&(w+="&fcl="+C.cookie.length)}catch(z){}q.performance&&q.performance.timing&&0<q.performance.timing.domainLookupStart&&0<q.performance.timing.domainLookupEnd&&(w+="&flt="+(q.performance.timing.domainLookupEnd-q.performance.timing.domainLookupStart));
C.querySelectorAll&&(w+="&fec="+C.querySelectorAll("*").length)}var t=w}catch(z){t=""}b=B+t;t=ba();b+="&vavbkt="+t.vdcd;b+="&lvvn="+t.vdcv;""!=t.err&&(b+="&dvp_idcerr="+encodeURIComponent(t.err));t="&eparams="+encodeURIComponent(I(c));return b=b.length+t.length<=h?b+t:b+"&dvf=3"}function ba(){var b=[],c=function(b){e(b,null!=b.AZSD,9);e(b,b.location.hostname!=b.encodeURIComponent(b.location.hostname),10);e(b,null!=b.cascadeWindowInfo,11);e(b,null!=b._rvz,32);e(b,null!=b.FO_DOMAIN,34);e(b,null!=b.va_subid,
36);e(b,b._GPL&&b._GPL.baseCDN,40);e(b,d(b,"__twb__")&&d(b,"__twb_cb_"),43);e(b,null!=b.landingUrl&&null!=b.seList&&null!=b.parkingPPCTitleElements&&null!=b.allocation,45);e(b,d(b,"_rvz",function(b){return null!=b.publisher_subid}),46);e(b,null!=b.cacildsFunc&&null!=b.n_storesFromFs,47);e(b,b._pcg&&b._pcg.GN_UniqueId,54);e(b,d(b,"__ad_rns_")&&d(b,"_$_"),64);e(b,null!=b.APP_LABEL_NAME_FULL_UC,71);e(b,null!=b._priam_adblock,81);e(b,b.supp_ads_host&&b.supp_ads_host_overridden,82);e(b,b.uti_xdmsg_manager&&
b.uti_xdmsg_manager.cb,87);e(b,b.LogBundleData&&b.addIframe,91);e(b,b.xAdsXMLHelperId||b.xYKAffSubIdTag,95);e(b,b.__pmetag&&b.__pmetag.uid,98);e(b,b.CustomWLAdServer&&/(n\d{1,4}adserv)|(1ads|cccpmo|epommarket|epmads|adshost1)/.test(b.supp_ads_host_overridden),100)},d=function(b,c,d){for(var e in b)if(-1<e.indexOf(c)&&(!d||d(b[e])))return!0;return!1},e=function(c,d,e){d&&-1==b.indexOf(e)&&b.push((c==window.top?-1:1)*e)};try{return function(){for(var b=window,d=0;10>d&&(c(b),b!=window.top);d++)try{b.parent.document&&
(b=b.parent)}catch(k){break}}(),{vdcv:28,vdcd:b.join(","),err:void 0}}catch(g){return{vdcv:28,vdcd:"-999",err:g.message||"unknown"}}}function O(b){var c=0,d;for(d in b)b.hasOwnProperty(d)&&++c;return c}function ca(b,c){a:{var d={};try{if(b&&b.performance&&b.performance.getEntries){var e=b.performance.getEntries();for(b=0;b<e.length;b++){var g=e[b],h=g.name.match(/.*\/(.+?)\./);if(h&&h[1]){var k=h[1].replace(/\d+$/,""),f=c[k];if(f){for(var l=0;l<f.stats.length;l++){var r=f.stats[l];d[f.prefix+r.prefix]=
Math.round(g[r.name])}delete c[k];if(!O(c))break}}}}var n=d;break a}catch(m){}n=void 0}if(n&&O(n))return n}function W(b,c,d,e){var g=e?"https:":P(),h=e?"https:":K(c.src),k="0";"https:"===h&&(k="1");var f=window._dv_win.document.visibilityState;window[b]=function(b){try{var e={};e.protocol=g;e.ssl=k;e.dv_protocol=h;e.serverPublicDns=b.ServerPublicDns;e.ServerPublicDns=b.ServerPublicDns;e.tagElement=c;e.redirect=d;e.impressionId=b.ImpressionID;window._dv_win.$dvbsr.tags.add(b.ImpressionID,e);if(c.dvFrmWin){var n=
window._dv_win.$dvbsr;c.dvFrmWin.$uid=b.ImpressionID;n.messages&&n.messages.startSendingEvents&&n.messages.startSendingEvents(c.dvFrmWin,b.ImpressionID)}(function(){function c(){var e=window._dv_win.document.visibilityState;"prerender"===f&&"prerender"!==e&&"unloaded"!==e&&(f=e,window._dv_win.$dvbsr.registerEventCall(b.ImpressionID,{prndr:0}),window._dv_win.document.removeEventListener(d,c))}if("prerender"===f)if("prerender"!==window._dv_win.document.visibilityState&&"unloaded"!==visibilityStateLocal)window._dv_win.$dvbsr.registerEventCall(b.ImpressionID,
{prndr:0});else{var d;"undefined"!==typeof window._dv_win.document.hidden?d="visibilitychange":"undefined"!==typeof window._dv_win.document.mozHidden?d="mozvisibilitychange":"undefined"!==typeof window._dv_win.document.msHidden?d="msvisibilitychange":"undefined"!==typeof window._dv_win.document.webkitHidden&&(d="webkitvisibilitychange");window._dv_win.document.addEventListener(d,c,!1)}})();var m=ca(window,{verifyc:{prefix:"vf",stats:[{name:"duration",prefix:"dur"}]}});m&&window._dv_win.$dvbsr.registerEventCall(b.ImpressionID,
m)}catch(u){}}}function V(b,c){window[b]=function(b){try{if(void 0==b.ResultID)document.write(1!=b?c.tagsrc:c.altsrc);else switch(b.ResultID){case 1:b.Passback?document.write(decodeURIComponent(b.Passback)):document.write(c.altsrc);break;case 2:case 3:document.write(c.tagsrc)}}catch(e){}}}function X(b){try{if(1>=b.depth)return{url:"",depth:""};var c=[];c.push({win:window.top,depth:0});for(var d,e=1,g=0;0<e&&100>g;){try{if(g++,d=c.shift(),e--,0<d.win.location.toString().length&&d.win!=b)return 0==
d.win.document.referrer.length||0==d.depth?{url:d.win.location,depth:d.depth}:{url:d.win.document.referrer,depth:d.depth-1}}catch(f){}var h=d.win.frames.length;for(var k=0;k<h;k++)c.push({win:d.win.frames[k],depth:d.depth+1}),e++}return{url:"",depth:""}}catch(f){return{url:"",depth:""}}}function I(b){new String;var c=new String,d;for(d=0;d<b.length;d++){var e=b.charAt(d);var g="!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".indexOf(e);0<=g&&(e="!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~".charAt((g+
47)%94));c+=e}return c}function Y(){try{if(null!=window._phantom||null!=window.callPhantom)return 99;if(document.documentElement.hasAttribute&&document.documentElement.hasAttribute("webdriver")||null!=window.domAutomation||null!=window.domAutomationController||null!=window._WEBDRIVER_ELEM_CACHE)return 98;if(void 0!=window.opera&&void 0!=window.history.navigationMode||void 0!=window.opr&&void 0!=window.opr.addons&&"function"==typeof window.opr.addons.installExtension)return 4;if(void 0!=document.uniqueID&&
"string"==typeof document.uniqueID&&(void 0!=document.documentMode&&0<=document.documentMode||void 0!=document.all&&"object"==typeof document.all||void 0!=window.ActiveXObject&&"function"==typeof window.ActiveXObject)||window.document&&window.document.updateSettings&&"function"==typeof window.document.updateSettings||Object.values&&navigator&&Object.values(navigator.plugins).some(function(b){return-1!=b.name.indexOf("Edge PDF")}))return 1;if(void 0!=window.chrome&&"function"==typeof window.chrome.csi&&
"function"==typeof window.chrome.loadTimes&&void 0!=document.webkitHidden&&(1==document.webkitHidden||0==document.webkitHidden))return 3;if(void 0!=window.mozInnerScreenY&&"number"==typeof window.mozInnerScreenY&&void 0!=window.mozPaintCount&&0<=window.mozPaintCount&&void 0!=window.InstallTrigger&&void 0!=window.InstallTrigger.install)return 2;var b=!1;try{var c=document.createElement("p");c.innerText=".";c.style="text-shadow: rgb(99, 116, 171) 20px -12px 2px";b=void 0!=c.style.textShadow}catch(d){}return(0<
Object.prototype.toString.call(window.HTMLElement).indexOf("Constructor")||window.webkitAudioPannerNode&&window.webkitConvertPointFromNodeToPage)&&b&&void 0!=window.innerWidth&&void 0!=window.innerHeight?5:0}catch(d){return 0}}function Z(){try{var b=0,c=function(c,d){d&&32>c&&(b=(b|1<<c)>>>0)},d=function(b,c){return function(){return b.apply(c,arguments)}},e="svg"===document.documentElement.nodeName.toLowerCase(),g=function(){return"function"!==typeof document.createElement?document.createElement(arguments[0]):
e?document.createElementNS.call(document,"http://www.w3.org/2000/svg",arguments[0]):document.createElement.apply(document,arguments)},h=["Moz","O","ms","Webkit"],k=["moz","o","ms","webkit"],f={style:g("modernizr").style},l=function(b,c){function d(){h&&(delete f.style,delete f.modElem)}var e;for(e=["modernizr","tspan","samp"];!f.style&&e.length;){var h=!0;f.modElem=g(e.shift());f.style=f.modElem.style}var k=b.length;for(e=0;e<k;e++){var l=b[e];~(""+l).indexOf("-")&&(l=cssToDOM(l));if(void 0!==f.style[l])return d(),
"pfx"==c?l:!0}d();return!1},r=function(b,c,e){var g=b.charAt(0).toUpperCase()+b.slice(1),f=(b+" "+h.join(g+" ")+g).split(" ");if("string"===typeof c||"undefined"===typeof c)return l(f,c);f=(b+" "+k.join(g+" ")+g).split(" ");for(var m in f)if(f[m]in c){if(!1===e)return f[m];b=c[f[m]];return"function"===typeof b?d(b,e||c):b}return!1};c(0,!0);c(1,r("requestFileSystem",window));c(2,window.CSS?"function"==typeof window.CSS.escape:!1);c(3,r("shapeOutside","content-box",!0));return b}catch(n){return 0}}
function J(){var b=window,c=0;try{for(;b.parent&&b!=b.parent&&b.parent.document&&!(b=b.parent,10<c++););}catch(d){}return b}function aa(){try{var b=J(),c=0,d=0,e=function(b,e,f){f&&(c+=Math.pow(2,b),d+=Math.pow(2,e))},g=b.document;e(14,0,b.playerInstance&&g.querySelector('script[src*="ads-player.com"]'));e(14,1,(b.CustomWLAdServer||b.DbcbdConfig)&&(a=g.querySelector('p[class="footerCopyright"]'),a&&a.textContent.match(/ MangaLife 2016/)));e(15,2,b.zpz&&b.zpz.createPlayer);e(15,3,b.vdApp&&b.vdApp.createPlayer);
e(15,4,g.querySelector('body>div[class="z-z-z"]'));e(16,5,b.xy_checksum&&b.place_player&&(b.logjwonready&&b.logContentPauseRequested||b.jwplayer));e(17,6,b==b.top&&""==g.title?(a=g.querySelector('body>object[id="player"]'),a&&a.data&&1<a.data.indexOf("jwplayer")&&"visibility: visible;"==a.getAttribute("style")):!1);e(17,7,g.querySelector('script[src*="sitewebvideo.com"]'));e(17,8,b.InitPage&&b.cef&&b.InitAd);e(17,9,b==b.top&&""==g.title?(a=g.querySelector("body>#player"),null!=a&&null!=(null!=a.querySelector('div[id*="opti-ad"]')||
a.querySelector('iframe[src="about:blank"]'))):!1);e(17,10,b==b.top&&""==g.title&&b.InitAdPlayer?(a=g.querySelector('body>div[id="kt_player"]'),null!=a&&null!=a.querySelector('div[class="flash-blocker"]')):!1);e(17,11,null!=b.clickplayer&&null!=b.checkRdy2);e(19,12,b.instance&&b.inject&&g.querySelector('path[id="cp-search-0"]'));e(20,13,function(){try{if(b.top==b&&0<b.document.getElementsByClassName("asu").length)for(var c=b.document.styleSheets,d=0;d<c.length;d++)for(var e=b.document.styleSheets[d].cssRules,
f=0;f<e.length;f++)if("div.kk"==e[f].selectorText||"div.asu"==e[f].selectorText)return!0}catch(v){}}());a:{try{var h=null!=g.querySelector('div[id="kt_player"][hiegth]');break a}catch(n){}h=void 0}e(21,14,h);a:{try{var k=b.top==b&&null!=b.document.querySelector('div[id="asu"][class="kk"]');break a}catch(n){}k=void 0}e(22,15,k);a:{try{var f=g.querySelector('object[data*="/VPAIDFlash.swf"]')&&g.querySelector('object[id*="vpaid_video_flash_tester_el"]')&&g.querySelector('div[id*="desktopSubModal"]');
break a}catch(n){}f=void 0}e(25,16,f);var l=navigator.userAgent;if(l&&-1<l.indexOf("Android")&&-1<l.indexOf(" wv)")&&b==window.top){var r=g.querySelector('img[src*="dealsneartome.com"]')||(b.__cads__?!0:!1)||0<g.querySelectorAll('img[src*="/tracker?tag="]').length;e(28,17,r||!1)}return{f:c,s:d}}catch(n){return null}}this.createRequest=function(){var b=!1,c=window,d=0,e=!1;try{for(dv_i=0;10>=dv_i;dv_i++)if(null!=c.parent&&c.parent!=c)if(0<c.parent.location.toString().length)c=c.parent,d++,b=!0;else{b=
!1;break}else{0==dv_i&&(b=!0);break}}catch(l){b=!1}a:{try{var g=c.$sf;break a}catch(l){}g=void 0}if(0==c.document.referrer.length)b=c.location;else if(b)b=c.location;else{b=c.document.referrer;if(x(b)){a:{try{var h=c.$sf&&c.$sf.ext&&c.$sf.ext.hostURL&&c.$sf.ext.hostURL();break a}catch(l){}h=void 0}if(h&&!x(h)&&0==h.indexOf(b)){b=h;var k=!0}}e=!0}if(!window._dv_win.bsredirect5ScriptsInternal||!window._dv_win.bsredirect5Processed||0==window._dv_win.bsredirect5ScriptsInternal.length)return{isSev1:!1,
url:null};this.dv_script_obj=h=R();h=this.dv_script=h.script;var f=h.src.replace(/^.+?callback=(.+?)(&|$)/,"$1");if(f&&(this.redirect=eval(f+"()"))&&!this.redirect.done){this.redirect.done=!0;if(Q(this.redirect))return{isSev1:!0};c=y(this.redirect,b,c,d,e,h&&h.parentElement&&h.parentElement.tagName&&"HEAD"===h.parentElement.tagName,h,k,g);c+="&"+this.getVersionParamName()+"="+this.getVersion();return{isSev1:!1,url:c}}};this.isApplicable=function(){return!0};this.onFailure=function(){};this.sendRequest=
function(b){dv_sendRequest(b);try{var c=S(this.dv_script_obj&&this.dv_script_obj.injScripts),d=L("about:blank");d.id=d.name;var e=d.id.replace("iframe_","");d.setAttribute&&d.setAttribute("data-dv-frm",e);D(d,this.dv_script);if(this.dv_script){var g=this.dv_script;a:{b=null;try{if(b=d.contentWindow){var h=b;break a}}catch(l){}try{if(b=window._dv_win.frames&&window._dv_win.frames[d.name]){h=b;break a}}catch(l){}h=null}g.dvFrmWin=h}var k=T(d);if(k)k.open(),k.write(c);else{try{document.domain=document.domain}catch(l){}var f=
encodeURIComponent(c.replace(/'/g,"\\'").replace(/\n|\r\n|\r/g,""));d.src='javascript: (function(){document.open();document.domain="'+window.document.domain+"\";document.write('"+f+"');})()"}}catch(l){c=(window._dv_win.dv_config=window._dv_win.dv_config||{}).tpsAddress||"tps30.doubleverify.com",dv_SendErrorImp(c+"/verifyc.js?ctx=818052&cmp=1619415",[{dvp_jsErrMsg:"DvFrame: "+encodeURIComponent(l)}])}return!0};window.debugScript&&(!window.minDebugVersion||10>=window.minDebugVersion)&&(window.DvVerify=
y,window.createRequest=this.createRequest);this.getVersionParamName=function(){return"ver"};this.getVersion=function(){return"82"}};


function dv_bs5_main(dv_baseHandlerIns, dv_handlersDefs) {

    this.baseHandlerIns = dv_baseHandlerIns;
    this.handlersDefs = dv_handlersDefs;

    this.exec = function () {
        try {
            window._dv_win = (window._dv_win || window);
            window._dv_win.$dvbsr = (window._dv_win.$dvbsr || new dvBsrType());

            window._dv_win.dv_config = window._dv_win.dv_config || {};
            window._dv_win.dv_config.bsErrAddress = window._dv_win.dv_config.bsAddress || 'rtb0.doubleverify.com';

            var errorsArr = (new dv_rolloutManager(this.handlersDefs, this.baseHandlerIns)).handle();
            if (errorsArr && errorsArr.length > 0)
                dv_SendErrorImp(window._dv_win.dv_config.bsErrAddress + '/verifyc.js?ctx=818052&cmp=1619415&num=5', errorsArr);
        }
        catch (e) {
            try {
                dv_SendErrorImp(window._dv_win.dv_config.bsErrAddress + '/verifyc.js?ctx=818052&cmp=1619415&num=5&dvp_isLostImp=1', {dvp_jsErrMsg: encodeURIComponent(e)});
            } catch (e) {
            }
        }
    }
}

try {
    window._dv_win = window._dv_win || window;
    var dv_baseHandlerIns = new dv_baseHandler();
	

    var dv_handlersDefs = [];

    if (!window.debugScript) {
    (new dv_bs5_main(dv_baseHandlerIns, dv_handlersDefs)).exec();
}
} catch (e) {
}