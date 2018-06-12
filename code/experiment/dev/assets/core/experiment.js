function Experiment(participantId)
{
    var id     = Id.generate();
    var self   = this;
    var errors = [];
    var post   = undefined;

    var canvas  = new Canvas(document.querySelector('#c'));
    var mouse   = new Mouse(canvas);
    var targets = new Targets(mouse, getFeatureWeights());
    var counter = new Counter(3, 3000, true);
    var timer   = new Timer(15000, true);
    
    canvas.draw = function() {
        targets.draw(canvas);
        counter.draw(canvas);
        timer  .draw(canvas);
        mouse  .draw(canvas);
        self   .draw(canvas);
    };
    
    var obs = new Observations(participantId, id, mouse, targets);
    var fps = new Frequency("fps", false);

    this.run = function() {
        if(!canvas.getContext2d()) {
            return $.Deferred.reject("HTML5 Canvas is not supported on this device");
        }
        else {
            return runCountdown().then(runTask).then(runCleanup);
        }
    }

    this.draw = function(canvas) {
        fps.cycle();
    }

    function getFeatureWeights() {
        //var r_param = [-0.0153,  0.0217,  0.0064, -0.0008, 0.0001]; //crazy back and forth
        //var r_param = [-0.1921, -0.0462, -0.0107, -0.0009, 0.0790]; //controlled and targeted
        var r_param = [0      ,0       ,0       ,0       ,1      ]; //the default color scheme
        
        return r_param;
    }
    
    function startExperiment() {
        fps.start();
        obs.startObserving();

        //not knowing how I may or may not want to modify opacity and color rules in the future I'm not going to guess and store
        //I do likely want to store feature weights still though. Perhaps I need to make a comprehensive list of features and use these.
        
        //Measurements to add: feature weights, touch count
        saveData({"startTime":new Date().toUTCString(), "dimensions": canvas.getDimensions(), "resolution": canvas.getResolution()});
    }

    function stopExperiment() {
        fps.stop();
        obs.stopObserving();
        
        saveData({"stopTime":new Date().toUTCString(), "fps": fps.getHz(), "ops": obs.getHz(), "errors" : errors.concat(obs.getErrors()).toDistinct()});
    }
    
    function runCountdown() {

        var deferred = $.Deferred();

        canvas .startAnimating();
        counter.startCounting();
        targets.startAppearing();
        mouse  .startTracking();

        counter.onElapsed(function() { deferred.resolve(); });

        return deferred;
    }
    
    function runTask() {
        var deferred = $.Deferred();
        
        startExperiment();
        
        timer.startTiming();
        timer.onElapsed(function() { deferred.resolve(); });
        
        return deferred;
    }

    function runCleanup() {
        mouse  .stopTracking();
        targets.stopAppearing();
        counter.stopCounting();
        canvas .stopAnimating();        
        timer  .stopTiming();
        
        stopExperiment();
    }
    
    function saveData(data) {        
        if(!post) {
            post = $.ajax({
                "url"   :"https://api.thesis.markrucker.net/v1/participants/" + participantId + "/experiments/" + id,
                "method":"POST",
                "data"  : JSON.stringify(data)
            });
        }
        else {
            post.done(function() {
                $.ajax({
                    "url"   :"https://api.thesis.markrucker.net/v1/participants/" + participantId + "/experiments/" + id,
                    "method":"PATCH",
                    "data"  : JSON.stringify(data)
                });
            });
        }
    }
}