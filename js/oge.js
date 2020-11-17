// © OpenGeoEdu 2020
// @license magnet:?xt=urn:btih:0b31508aeb0634b347b8270c7bee4d411b5d4109&dn=agpl-3.0.txt AGPL v3.0


document.body.style.background = "#E2F4FB"; //"#E3EBF3";

// Filter only one value of the "select"-"group"
toggleFilterExclusive = function(value, obj){

};

toggleFilter = function(value, obj){
  var filterGroups = document.getElementsByClassName("main-filter-group");
  for (var k = 0; k < filterGroups.length; k++) {
    var filterGroup = filterGroups[k];
    var checkboxes = filterGroup.getElementsByClassName("crosstalk_checkbox");
  //  alert(checkboxes.length);
    for (var i = 0; i < checkboxes.length; i++) {
        var checkbox = checkboxes[i];
        if(checkbox.value == value && checkbox.checked != obj.checked) {
          checkbox.click();
        }
    }
  }
};


changeFun = function(value, obj){
 // alert('Changed value of '+value+" to "+obj.checked);
  
  var checkboxes = document.getElementsByClassName("crosstalk_checkbox");
  for (var i = 0; i < checkboxes.length; i++) {
      var checkbox = checkboxes[i];
      if(checkbox.value == value && checkbox.checked != obj.checked) {
        checkbox.checked = obj.checked;
      }
  }
};


var filterGroups = document.getElementsByClassName("main-filter-group");

for (var k = 0; k < filterGroups.length; k++) {
  var filterGroup = filterGroups[k];
  var x = filterGroup.getElementsByClassName("crosstalk-input-checkboxgroup");
  var i;
  for (i = 0; i < x.length; i++) {
      var inputs = x[i].getElementsByTagName("input");
      for (var j = 0; j < inputs.length; j++) {
        input = inputs[j];
        input.className = "crosstalk_checkbox";
        input.nextElementSibling.className = "checkbox_label";
        var parent = input.parentNode;
        parent.className = (parent.className + " checkbox_container").trim();
        var checkmark = document.createElement('span');
        checkmark.className = "checkmark";
        // set element as child of input
        parent.insertBefore(checkmark, input.nextSibling);
      // input.checked = true;
        input.setAttribute("onchange", "changeFun('"+input.getAttribute("value")+"', this)");
        input.click();
      }
  }
}
  

// insert link to www.opengeoedu.de where the logo is
//---------------------------------------------------
var logoNode = document.getElementsByClassName("navbar-logo")[0];
//alert(logoNode);
var ogoelink = document.createElement('a');
ogoelink.href = "https://www.opengeoedu.de";
ogoelink.target = "_blank";
ogoelink.title = "Projekt-Website";
// replace logo with link node
logoNode.parentNode.replaceChild(ogoelink, logoNode);
// make logo child of link (i.e. a clickable image)
ogoelink.appendChild(logoNode);

 

var c_select = document.getElementById('country_select');
var scripts = c_select.getElementsByTagName('script');
for(i = 0; i < scripts.length; i++){
  if(scripts[i].getAttribute('data-for') == 'country_select'){
    var dataNode = scripts[i];
    dataNode.innerHTML =  document.getElementById('country_select_map').innerHTML;
  
  }
}


// some map elements (mostly tooltips are not multilingual. In the following, the English labels are replaced by German)
// ------------------------------
updateSelectTool = function(){
  mapcontrols  = document.getElementsByClassName("select-inactive-active");
  if(mapcontrols.length >0)
    mapcontrols[0].title = "Rechteckauswahl (aktiv auf Karte und Tabelle)";

  mapcontrols  = document.getElementsByClassName("select-active-active");
  if(mapcontrols.length >0)
    mapcontrols[0].title = "Auswahl aufheben (auf Karte und Tabelle)";

};

var zoomscaling = false;

onRenderMap = function(){

  var mapcontrols = document.getElementsByClassName("leaflet-control-zoom-in");
  if( mapcontrols .length >0)
      mapcontrols[0].title = "Vergrößern";
      mapcontrols  = document.getElementsByClassName("leaflet-control-zoom-out");
  if(mapcontrols.length >0)
    mapcontrols[0].title = "Verkleinern";
  mapcontrols  = document.getElementsByClassName("leaflet-control-fullscreen-button");
  if(mapcontrols.length >0)
     mapcontrols[0].title = "Vollbild";
  mapcontrols  = document.getElementsByClassName("select-inactive-active");
  if(mapcontrols.length >0){
    mapcontrols[0].setAttribute("onClick","updateSelectTool()");
    updateSelectTool();
  }
  mapcontrols  = document.getElementsByClassName("unnamed-state-active");
  if(mapcontrols.length >0)
      mapcontrols[0].title = "Ansicht zurücksetzen (reset)";
  mapcontrols  = document.getElementsByClassName("search-button");
  if(mapcontrols.length >0)
      mapcontrols[0].title = "Suche nach Ort oder Name eines Portals";

  style_selector = -1;
  for(var i = 0; i < document.styleSheets.length; i++){
    var href = document.styleSheets[i].href;
    if(href && href.endsWith("dynamic.css")){
      style_selector = i;
      break;
    }
  }
  if(style_selector != -1){
    document.styleSheets[style_selector].insertRule(".leaflet-marker-icon { width: 10px !important; height: 10px !important;}", 0);
    zoomscaling = true;
    console.log("Dynamic scaling of makers initiated");
  }else{
    console.error("Dynamic scaling could not be initiated (stylesheet dynamic.css not found?)");
  }
};


$.fn.dataTable.ext.type.order['range-order-pre'] = function ( d ) {
  switch ( d ) {
      case 'international':    return 1;
      case 'national': return 2;
      case 'regional':   return 3;
      case 'kommunal':   return 4;
  }
  return 0;
};



/** Dynamic zooming, depending on zoom three different levels. Note that the scale html widget (in kilometres) is required to determine the zoom scale **/
var zoom_level = 1;

zoomObserver = function(){
  if(!zoomscaling){
    return 0;
  }
  var div_scale_line = document.getElementsByClassName("leaflet-control-scale-line")[0];
  if(div_scale_line == undefined){
    return 0;
  }
   var zoom = parseInt(div_scale_line.textContent.split(" ")[0]);
  //console.log(zoom);
   // on startup, the scale shoud should show >= 100 km
  if(zoom >=100){
    if(zoom_level !=1){
      
      document.styleSheets[style_selector].deleteRule(0);
      document.styleSheets[style_selector].insertRule(".leaflet-marker-icon { width: 8px !important; height: 8px !important;}", 0);
      zoom_level = 1;
    }
  } else if(zoom >=50){
    if(zoom_level !=2){
      document.styleSheets[style_selector].deleteRule(0);
      document.styleSheets[style_selector].insertRule(".leaflet-marker-icon { width: 15px !important; height: 15px !important;}", 0);
      zoom_level = 2;
    }
  } else if(zoom >=30){
    if(zoom_level !=3){
      document.styleSheets[style_selector].deleteRule(0);
      document.styleSheets[style_selector].insertRule(".leaflet-marker-icon { width: 22px !important; height: 22px !important;}", 0);
      zoom_level = 3;
    }
  }else if(zoom_level !=4 ){
      document.styleSheets[style_selector].deleteRule(0);
      document.styleSheets[style_selector].insertRule(".leaflet-marker-icon { width: 30px !important; height: 30px !important;}", 0);
      zoom_level = 4;
  } 
  
};


window.setInterval(zoomObserver, 200);
  
 /*if(){
    
  }*/
//};

//document.styleSheets[1].insertRule(".leaflet-marker-icon {  width: 3px !important;}", 0);


/*
activerule = false;
zoomlevel = -1;
zoomObserver2 = function(){
  var div_scale_set = document.getElementsByClassName("leaflet-control-scale-line");
  var zoom = parseInt(div_scale_set[0].textContent.split(" ")[0]);
     
  if(zoomlevel == -1){
    
  } 
  
 /*if(){
    
  }*/
//};



/*

small_scale = true;
zoomObserver = function(){
  var div_scale_set = document.getElementsByClassName("leaflet-control-scale-line");
  if(div_scale_set.length > 0){
    //console.log();
    var zoom = parseInt(div_scale_set[0].textContent.split(" ")[0]);
    if(activerule && ((zoom > 30 && !small_scale) || (zoom <= 30 && small_scale))){
      document.styleSheets[0].deleteRule(0);
      activerule = false;
    } 

    if(!activerule){
      if(zoom > 30){
        document.styleSheets[0].insertRule(".leaflet-marker-icon { width: 15px !important; height: 15px !important;}", 0);
        small_scale = true;
        activerule = true;
      }
    }
  }
 // alert('test')
};

//document.getElementsByClassName("leaflet-control-scale-line")[0].setAttribute("oninput", zoomObserver);

//window.setInterval(zoomObserver, 200);


$(document).on('shiny:value', function(event) {
  //event.preventDefault();
  console.log("test");
});

*/

// @license-end