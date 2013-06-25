/*
 jQuery delayed observer - 0.3
 (c) 2007 ~ Maxime Haineault (haineault@gmail.com)
 
 MIT License (http://www.opensource.org/licenses/mit-license.php)
 
 changelog
 ---------
 0.2 using closure, special thanks to Stephen Goguen & Tane Piper.
 0.3 now allow object chaining, added license
*/

(function() {
  var delayedObserverStack = [];
  var observed;
 
  function delayedObserverCallback(stackPos) {
    observed = delayedObserverStack[stackPos];
    if (observed.timer) clearTimeout(observed.timer);
   
    observed.timer = setTimeout(function(){
      observed.timer = null;
      observed.callback(observed.obj.val(), observed.obj);
    }, observed.delay * 1000);

    observed.oldVal = observed.obj.val();
  } 
 
  jQuery.fn.extend({
    delayedObserver:function(delay, callback){
      $this = $(this);
     
      delayedObserverStack.push({
        obj: $this, timer: null, delay: delay,
        oldVal: $this.val(), callback: callback
      });
       
      stackPos = delayedObserverStack.length-1;
     
      $this.keyup(function() {
        observed = delayedObserverStack[stackPos];
          if (observed.obj.val() == observed.obj.oldVal) return;
          else delayedObserverCallback(stackPos);
      });
      return this;
    }
  });
})();

