streamElements = {} # keep track of DOM elements for each stream

# Whenever updateViews are involved, parameters passed through will always have:
# TBPublisher constructor, TBUpdateObjects, TBSubscriber constructor
# [id, top, left, width, height, zIndex, ... ]

#
# Helper methods
#
getPosition = (pubDiv) ->
  # Get the position of element
  if !pubDiv then return {}
  return pubDiv.getBoundingClientRect()

replaceWithVideoStream = (element, streamId, properties) ->
  typeClass = if streamId == PublisherStreamId then PublisherTypeClass else SubscriberTypeClass
  if (properties.insertMode == "replace")
    newElement = element
  else
    newElement = document.createElement( "div" )
  newElement.setAttribute( "class", "OT_root #{typeClass}" )
  newElement.setAttribute( "data-streamid", streamId )
  newElement.setAttribute( "data-insertMode", properties.insertMode )
  if (typeof properties.width is 'string')
    newElement.style.width = properties.width
  else
    newElement.style.width = properties.width+"px"
  if (typeof properties.height is 'string')
    newElement.style.height = properties.height
  else
    newElement.style.height = properties.height+"px"
  newElement.style.overflow = "hidden"
  newElement.style['background-color'] = "#000000"
  streamElements[ streamId ] = newElement

  internalDiv = document.createElement( "div" )
  internalDiv.setAttribute( "class", VideoContainerClass)
  internalDiv.style.width = "100%"
  internalDiv.style.height = "100%"
  internalDiv.style.left = "0px"
  internalDiv.style.top = "0px"

  videoElement = document.createElement( "video" )
  videoElement.style.width = "100%"
  videoElement.style.height = "100%"
  # todo: js change styles or append css stylesheets? Concern: users will not be able to change via css

  internalDiv.appendChild( videoElement )
  newElement.appendChild( internalDiv )

  if (properties.insertMode == "append")
    element.appendChild(newElement)
  if (properties.insertMode == "before")
    element.parentNode.insertBefore(newElement, element)
  if (properties.insertMode == "after")
    element.parentNode.insertBefore(newElement, element.nextSibling)
  return newElement

TBError = (error) ->
  console.log("Error: ", error)

TBSuccess = ->
  console.log("success")

OTPublisherError = (error) ->
  if error == "permission denied"
    OTReplacePublisher()
    TBError("Camera or Audio Permission Denied")
  else
    TBError(error)

TBUpdateObjects = ()->
  console.log("JS: Objects being updated in TBUpdateObjects")
  updateObject = (e, time) ->
    setTimeout(() ->
      ratios = TBGetScreenRatios()
      streamId = e.dataset.streamid
      position = getPosition(e)
      zIndex = TBGetZIndex(e)
      borderRadius = TBGetBorderRadius(e)
      if e.TBBorderRadius != borderRadius || !e.TBPosition || position.top != e.TBPosition.top || position.left != e.TBPosition.left || position.width != e.TBPosition.width || position.height != e.TBPosition.height || zIndex != e.TBZIndex
        console.log("JS: Object updated with sessionId " + streamId + " updated");
        e.TBPosition = position;
        e.TBZIndex = zIndex;
        e.TBBorderRadius = borderRadius;
        Cordova.exec(TBSuccess, TBError, OTPlugin, "updateView", [streamId, position.top, position.left, position.width, position.height, zIndex, ratios.widthRatio, ratios.heightRatio, borderRadius]);
    , time)
    return

  objects = document.getElementsByClassName('OT_root')
  for e in objects
    streamId = e.dataset.streamid
    time = 0
    if typeof window.angular != "undefined" || typeof window.Ionic != "undefined"
      if OT.timeStreamCreated[streamId]
        time = performance.now() - OT.timeStreamCreated[streamId]
        delete OT.timeStreamCreated[streamId]
    updateObject(e, time)
  return

TBGenerateDomHelper = ->
  domId = "PubSub" + Date.now()
  div = document.createElement('div')
  div.setAttribute( 'id', domId )
  document.body.appendChild(div)
  return domId

TBGetZIndex = (ele) ->
  while( ele? )
    val = document.defaultView.getComputedStyle(ele,null).getPropertyValue('z-index')
    if ( parseInt(val) )
      return val
    ele = ele.offsetParent
  return 0

TBGetBorderRadius = (ele) ->
  radii = [0, 0, 0, 0, 0, 0, 0, 0]
  while (ele?)
    style = window.getComputedStyle(ele, null)
    radius = style.borderRadius.split(' ')
    if radius.length == 0 || radius.length == 1 && parseFloat(radius[0]) == 0
      ele = ele.offsetParent
    else
      pos = getPosition(ele)
      radiars = [
        { radius: style.borderTopLeftRadius.split(' '), borderX: parseFloat(style.borderLeftWidth), borderY: parseFloat(style.borderTopWidth) },
        { radius: style.borderTopRightRadius.split(' '), borderX: parseFloat(style.borderRightWidth), borderY: parseFloat(style.borderTopWidth) },
        { radius: style.borderBottomRightRadius.split(' '), borderX: parseFloat(style.borderRightWidth), borderY: parseFloat(style.borderBottomWidth) },
        { radius: style.borderBottomLeftRadius.split(' '), borderX: parseFloat(style.borderLeftWidth), borderY: parseFloat(style.borderBottomWidth) }
      ]

      calculate = (radius, z) ->
        if radius.indexOf('%') > -1
          return (z / 100) * parseFloat(radius)
        else
          return parseFloat(radius)

      count = 0
      for radiar in radiars
        x = y = calculate(radiar.radius[0], pos.width)
        if radiar.radius.length == 2
          y = calculate(radiar.radius[1], pos.height)

        radii[count++] = x - radiar.borderX
        radii[count++] = y - radiar.borderY
      break;
  return radii.join(' ')

TBGetScreenRatios = ()->
    # Ratio between browser window size and viewport size
    return {
        widthRatio: window.outerWidth / window.innerWidth,
        heightRatio: window.outerHeight / window.innerHeight
    }

OTReplacePublisher = ()->
    # replace publisher because permission denied
    elements = document.getElementsByClassName('OT_root OT_publisher');
    for el in elements
      elAttribute = el.getAttribute('data-streamid')
      if elAttribute == "TBPublisher"
        element = el
        break
    attributes = ['style', 'data-streamid', 'class']
    elementChildren = element.childNodes
    element.removeAttribute attribute for attribute in attributes
    for childElement in elementChildren
      childClass = childElement.getAttribute 'class'
      if childClass == 'OT_video-container'
        element.removeChild childElement
        break
    return

OTObserveVideoContainer = (() ->
  videoContainerObserver = new MutationObserver((mutations) ->
    for mutation in mutations
      if mutation.attributeName == 'style' || mutation.attributeName == 'class'
        TBUpdateObjects();
  )
  return (videoContainer) ->
    # If already observed, just update, else observe.
    if(videoContainer._OTObserved)
      TBUpdateObjects(videoContainer)
    else
      videoContainer._OTObserved = true;
      videoContainerObserver.observe(videoContainer, {
        # Set to true if additions and removals of the target node's child elements (including text nodes) are to be observed.
        childList: false
        # Set to true if mutations to target's attributes are to be observed.
        attributes: true
        # Set to true if mutations to target's data are to be observed.
        characterData: false
        # Set to true if mutations to not just target, but also target's descendants are to be observed.
        subtree: true
        # Set to true if attributes is set to true and target's attribute value before the mutation needs to be recorded.
        attributeOldValue: false
        # Set to true if characterData is set to true and target's data before the mutation needs to be recorded.
        characterDataOldValue: false
        # Set to an array of attribute local names (without namespace) if not all attribute mutations need to be observed.
        attributeFilter: ['style', 'class']
      })
)()
OTDomObserver = new MutationObserver((mutations) ->
  getVideoContainer = (node) ->
    if typeof node.querySelector != 'function'
      return

    videoElement = node.querySelector('video')
    if videoElement
      while (videoElement = videoElement.parentNode) && !videoElement.hasAttribute('data-streamid')
        continue
      return videoElement
    return false

  checkNewNode = (node) ->
    videoContainer = getVideoContainer(node)
    if videoContainer
      OTObserveVideoContainer(videoContainer)

  checkRemovedNode = (node) ->
    # Stand-in, if we want to trigger things in the future(like emitting events).
    return

  for mutation in mutations
    # Check if its attributes that have changed(including children).
    if mutation.type == 'attributes'
      videoContainer = getVideoContainer(mutation.target)
      if videoContainer
        TBUpdateObjects()
      continue

    # Check if there has been addition or deletion of nodes.
    if mutation.type != 'childList'
      continue

    # Check added nodes.
    for node in mutation.addedNodes
      checkNewNode(node)

    # Check removed nodes.
    for node in mutation.removedNodes
      checkRemovedNode(node)

  return
)

pdebug = (msg, data) ->
  #console.log "JS Lib: #{msg} - ", data

OTOnScrollEvent = (e) ->
  target = e.target;
  videos = target.querySelectorAll('[data-streamid]')
  if(videos)
    for video in videos
      position = getPosition(video)
      Cordova.exec(TBSuccess, TBError, OTPlugin, "updateCamera", [video.getAttribute('data-streamid'), position.top, position.left, position.width, position.height] )
