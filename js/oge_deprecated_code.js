/*var x = document.getElementsByClassName("crosstalk-input-checkboxgroup");
  for (var j = 0; j < x.length; j++) {
    var checkboxes = x[j].getElementsByTagName("input");
     var noneselected = true;
    for (var i = 0; i < checkboxes.length; i++) {
      var checkbox = checkboxes[i];
       //checkbox.parentNode.className = (checkbox.parentNode.className + " noneselected").trim();
      if(checkbox.value == value && checkbox.checked != obj.checked) {
        //checkbox.checked = obj.checked;
        checkbox.click();
        noneselected = noneselected && !(checkbox.checked);
      }

    }*/
    /*for (var i = 0; i < checkboxes.length; i++) {
      var checkbox = checkboxes[i];
      if(noneselected){
        //alert("noneselected!");
        checkbox.parentElement.className = (checkbox.parentElement.className + " noneselected").trim();
      } else {
        checkbox.parentElement.className = checkbox.parentElement.className.replace("noneselected","").trim();
      }
    }
  
  }*/
/*
var x = document.getElementsByClassName("crosstalk-input-checkboxgroup");
  for (var j = 0; j < x.length; j++) {
   // var noneselected = true;
    var checkboxes = x[j].getElementsByTagName("input");
    for (var i = 0; i < checkboxes.length; i++) {
      var checkbox = checkboxes[i];
      if(checkbox.value == value && checkbox.checked != obj.checked) {
        checkbox.checked = obj.checked;
      }
     // noneselected = noneselected && !(checkbox.checked);

    }

    /* for (var i = 0; i < checkboxes.length; i++) {
      if(noneselected){
        alert("noneselected!");
        checkbox[i].parentElement.className = (checkbox[i].parentElement.className + " noneselected").trim();
      } else {
        checkbox[i].parentElement.className = checkbox[i].parentElement.className.replace("noneselected","").trim();
      }
    }
  }

}*/



/*var sections = document.getElementsByClassName("section level1");
//var sections = document.getElementsByTagName("div");
alert("Found "+sections.length+" sections");

for (i = 0; i < sections.length; i++) {
    var section = sections[i];
    var footer = document.createElement('div');
    footer.innerHTML = "<p>Test footer</p>";
//    footer.className = "section level1 vertical-layout-fill dashboard-row-orientation";
//footer.className = "section level1 vertical-layout-fill dashboard-row-orientation";
    section.parentElement.insertBefore(footer, sections.nextSibling);

}*/





//




     /* var mapicons = document.getElementsByClassName("leaflet-marker-icon");
     // alert(mapicons[1].getAttributeNode("height"));
     for (var i; i < mapicons.length; i++){
      mapicons[i].style.width = "10px";
      mapicons[i].style.height="10px";
     }*/
     /*mapicons[1].setAttribute("height", "500px");
     mapicons[1].setAttribute("width", "500px");
     alert(mapicons[1].getAttribute("height"));
      /*
      var markerIcons = document.getElementsByClassName("leaflet-marker-icon");
	//alert(markerIcons.length);
 for (i = 0; i < markerIcons.length; i++) {
 	var markerIcon = markerIcons[i];
//alert(markerIcon);
   markerIcon.style.width = "5px";
   markerIcon.style.height = "5px";   
 }
 alert("test"); */
};

/*
$.fn.dataTable.enum( [ 'international', 'national', 'regional','kommunal' ] );
$('#portals_table').DataTable();
*/







//$(document).on('click', function (e) {
  /*if ($(e.target).closest("#CONTAINER").length === 0) {
      $("#CONTAINER").hide();
  }*/


//});


  /*var buttons = document.getElementsByClassName("leaflet-popup-close-button");
  for (var index = 0; index < buttons.length; index++) {
     buttons[index].click();
    
  }*/
//  $(".leaflet-popup-close-button")[0].click();




/// in previous leaflet versions, pop-ups were not closing automatically
 /*var closefunction = function(){   
          var buttons = document.getElementsByClassName("leaflet-popup-close-button");
          for (var index = 0; index < buttons.length; index++) {
            buttons[index].click();
            
          }
        };
 var clickables = document.getElementsByClassName("polygonShape");
 for (var index = 0; index < clickables.length; index++) {
   clickables[index].addEventListener("click", closefunction);   
 }*/