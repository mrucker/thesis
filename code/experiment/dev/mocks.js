const utf8CharacterSize = 1; //byte

$.ajax = function(params) {
    
    requestStats.totalCount++;
    requestStats.totalSize += params.data.length * utf8CharacterSize;

    console.log(params);
    
    return $.Deferred().resolve();
}