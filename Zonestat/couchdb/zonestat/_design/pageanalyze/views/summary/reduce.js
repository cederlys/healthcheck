// "average_compression_ratio_percent":20.8378357341649,"compressed_resources":11,
// "effective_compression_ratio_percent":74.7202007651954

function(keys, values, rereduce) {
    return {
        "total_bytes": stats(values.map(function(e){return e.total_bytes;}), rereduce, 1024),
        "total_time": stats(values.map(function(e){return e.total_time}), rereduce, 1000),
        "total_requests": stats(values.map(function(e){return e.total_requests}), rereduce),
        "external_resources": stats(values.map(function(e){return e.external_resources}), rereduce),
        "average_compression_ratio_percent": stats(values.map(function(e){return e.average_compression_ratio_percent}), rereduce),
        "compressed_resources": stats(values.map(function(e){return e.compressed_resources}), rereduce),
        "effective_compression_ratio_percent": stats(values.map(function(e){return e.effective_compression_ratio_percent}), rereduce)
    };
}

function stats(values, rereduce, scale) {
    // This computes the standard deviation of the mapped results
    var stdDeviation=0.0;
    var count=0;
    var total=0.0;
    var sqrTotal=0.0
    var max=-Infinity;
    var min=Infinity;
    
    if(scale == null) {
        scale = 1;
    }

    if (!rereduce) {
        // This is the reduce phase, we are reducing over emitted values from
        // the map functions.
        for(var i in values) {
            var kb = values[i] / scale;
            total = total + kb;
            sqrTotal = sqrTotal + (kb * kb);
            if(kb > max) {
                max = kb;
            }
            if(kb < min) {
                min = kb;
            }
        }
        count = values.length;
    }
    else {
        // This is the rereduce phase, we are re-reducing previosuly
        // reduced values.
        for(var i in values) {
            count = count + values[i].count;
            total = total + values[i].total;
            sqrTotal = sqrTotal + values[i].sqrTotal;
            if(values[i].max > max) {
                max = values[i].max;
            }
            if(values[i].min < min) {
                min = values[i].min;
            }
        }
    }

    var variance =  (sqrTotal - ((total * total)/count)) / count;
    stdDeviation = Math.sqrt(variance);

    // the reduce result. It contains enough information to be rereduced
    // with other reduce results.
    return {"stdDeviation":stdDeviation,"count":count,
    "total":total,"sqrTotal":sqrTotal, "average": (total/count),
    "max": max, "min":min };
}