# Subscriber Object:
#   Properties:
#     id (string) - dom id of the subscriber
#     stream (Stream) - stream to which you are subscribing
#   Methods: 
#     getAudioVolume()
#     getImgData() : String
#     getStyle() : Objects
#     off( type, listener ) : objects
#     on( type, listener ) : objects
#     setAudioVolume( value ) : subscriber
#     setStyle( style, value ) : subscriber
#     subscribeToAudio( value ) : subscriber
#     subscribeToVideo( value ) : subscriber
class TBSubscriber
  getAudioVolume: ->
    return 0
  getImgData: ->
    return ""
  getStyle: ->
    return {}
  setAudioVolume:(value) ->
    return @
  setStyle: (style, value) ->
    return @
  off: (event, handler) ->
    return @
  on: (event, handler) ->
    return @
  subscribeToAudio: (value) ->
    state = "true"
    if value? and ( value == false or value == "false" )
      state = "false"
    Cordova.exec(TBSuccess, TBError, OTPlugin, "subscribeToAudio", [@streamId, state] );
    return @
  subscribeToVideo: (value) ->
    state = "true"
    if value? and ( value == false or value == "false" )
      state = "false"
    Cordova.exec(TBSuccess, TBError, OTPlugin, "subscribeToVideo", [@streamId, state] );
    return @

  constructor: (stream, divObject, properties) ->
    if divObject instanceof Element
      @element = divObject
      @id = @element.id
    else
      @id = divObject
      @element = document.getElementById(divObject)

    @streamId = stream.streamId
    @stream = stream
    divPosition = getPosition(@element)
    subscribeToVideo="true"
    zIndex = TBGetZIndex(@element)
    insertMode = "replace"
    if(properties?)
      width = properties.width || divPosition.width
      height = properties.height || divPosition.height
      name = properties.name ? ""
      subscribeToVideo = "true"
      subscribeToAudio = "true"
      if(properties.subscribeToVideo? and properties.subscribeToVideo == false)
        subscribeToVideo="false"
      if(properties.subscribeToAudio? and properties.subscribeToAudio == false)
        subscribeToAudio="false"
      insertMode = properties.insertMode ? insertMode
    if (not width?) or width == 0 or (not height?) or height==0
      width = DefaultWidth
      height = DefaultHeight
    obj = replaceWithVideoStream(@element, stream.streamId, {width:width, height:height, insertMode:insertMode})
    # If element is not yet in body, set it to 0 and then the observer will set it properly.
    if !document.body.contains(@element)
      width = 0;
      height = 0;
    position = getPosition(@element)
    borderRadius = TBGetBorderRadius(@element)
    ratios = TBGetScreenRatios()
    OT.getHelper().eventing(@)
    Cordova.exec(TBSuccess, TBError, OTPlugin, "subscribe", [stream.streamId, position.top, position.left, width, height, zIndex, subscribeToAudio, subscribeToVideo, ratios.widthRatio, ratios.heightRatio, borderRadius] )
    Cordova.exec(@eventReceived, TBSuccess, OTPlugin, "addEvent", ["subscriberEvents"] )

  eventReceived: (response) =>
    pdebug "subscriber event received", response
    if typeof @[response.eventType] == "function"
      @[response.eventType](response.data)
    else
      pdebug "No method found for EventType: '" + response.eventType + "'";
  connected: (event) =>
    streamEvent = new TBEvent("connected")
    streamEvent.stream = event.streamId
    @dispatchEvent(streamEvent)
    return @
  disconnected: (event) =>
    streamEvent = new TBEvent("disconnected")
    streamEvent.stream = event.streamId
    @dispatchEvent(streamEvent)
    return @
  videoDataReceived: (event) =>
    streamEvent = new TBEvent("videoDataReceived")
    @dispatchEvent(streamEvent)
    return @
  videoDisabled: (event) =>
    streamEvent = new TBEvent("videoDisabled")
    streamEvent.reason = event.reason
    @dispatchEvent(streamEvent)
    return @
  videoDisabledWarning: (event) =>
    streamEvent = new TBEvent("videoDisabledWarning")
    @dispatchEvent(streamEvent)
    return @
  videoDisabledWarningLifted: (event) =>
    streamEvent = new TBEvent("videoDisabledWarningLifted")
    @dispatchEvent(streamEvent)
    return @
  videoEnabled: (event) =>
    streamEvent = new TBEvent("videoEnabled")
    streamEvent.reason = event.reason
    @dispatchEvent(streamEvent)
    return @
  audioLevelUpdated: (event) =>
    streamEvent = new TBEvent("audioLevelUpdated")
    streamEvent.audioLevel = event.audioLevel
    return @

  # deprecating
  removeEventListener: (event, listener) ->
    return @
