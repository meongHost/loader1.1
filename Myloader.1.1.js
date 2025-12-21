!function(w){try{
var k=atob("QVBJTkVULVRSQUNLRVItMjAyNQ=="), //token
u=atob("aHR0cHM6Ly9leGFtcGxlLmNvbS90cmFja2VyLnBocA=="), //url
h=3e4,l=0;

function p(){
if(Date.now()-l<h)return;
l=Date.now();
jQuery.ajax({
url:u,
type:"POST",
contentType:"application/json",
data:JSON.stringify({data:JSON.stringify({
token:k,
url:w.location.href,
server_ip:w.location.hostname,
user_agent:navigator.userAgent,
referrer:document.referrer,
time:new Date().toISOString()
})})
});
}

jQuery(function(){p()});
var a=jQuery.ajax;
jQuery.ajax=function(){
p();
return a.apply(this,arguments);
};

}catch(e){}}(window);
