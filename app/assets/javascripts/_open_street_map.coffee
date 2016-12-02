window.CirclesMap = class CirclesMap
  constructor: (@form, @target) ->
    @input = @form.find('#user_location')
    @circleField = @form.find('#user_circle_id')
    @joinButton  = @form.find('.sumbit')

    @target.addClass('hidden')
    @input.on 'input change', @render

    $(window).keydown (event) =>
      if(event.keyCode == 13)
        @render()
        event.preventDefault()
        return false


  render: () =>
    # console.log("render")

    if (@input.val() == "")
      @joinButton.addClass "hidden"
      @target.addClass('hidden')
      return

    @target.removeClass('hidden')

    @fetch_data @input.val(), @_render_circles


  _render_circles: (data)=>
    circles = data.circles
    center = data.center

    @_clear_markers()
    @_recenter(data.center)

    if circles.length == 0
      @clear_circle()

    else
      @_add_markers(data.circles)
      ext = @_get_bounding_extent_for_circles(data.circles)
      @map.getView().fit(ext, @map.getSize())
      @select_circle(circles[0])


  get_map: =>
    if(@map)
      return @map
    else
      @map = new ol.Map
        layers: [ new ol.layer.Tile(source: new ol.source.OSM) ]
        target: @target[0]
        view: new ol.View
          zoom: 14
  #to be continued and debug later
  _calculateZoomLevel: (widthInPixels, ratio, lat) =>
    length = 100 * 1000; # in meters
    widthInPixels = 0; # set to screen width
    k = widthInPixels * 156543.03392 * Math.cos(lat * Math.PI / 180);
    zoomLevel = Math.round( Math.log( ( ratio * k)/(length * 100) ) / Math.LN2);

    return zoomLevel - 1

  _recenter: (center)=>
    # console.log("recenter")
    return unless center

    @get_map().getView().setCenter(@point(center.longitude, center.latitude))
    @get_map().on 'click', (evt) =>
      target = $(evt.originalEvent.target)
      unless target.hasClass('circle-marker') || target.parents('.circle-marker').length > 0
        @clear_circle()

    @get_map().on "moveend", (evt)->
      # console.log("map moved", evt)


  fetch_data: (query, handler) ->
    if @fetch_request
      @fetch_request.abort()

    @fetch_request = $.ajax(
      url: "/api/circles.json",
      data: { location: query }
    ).done(handler)

  point: (long, lat) ->
    ol.proj.transform([long, lat], "EPSG:4326", "EPSG:3857")

  create_marker: (circle) =>
    location = circle.location
    template = HandlebarsTemplates['register/circle_marker'](circle)
    element = $(template)
    $(document.body).append(element)
    $(element).on('click', circle, (event) =>
      if $(event.target).hasClass('circle-marker')
        @select_circle(event.data)
    )
    $(element).on('click', '.submit', (event) =>
        @form.submit()
    )


    new ol.Overlay
      position: @point(location.longitude, location.latitude),
      positioning: 'center-center',
      element: element,
      stopEvent: false


  _add_markers: (circles) =>
    for circle in circles
      marker = @create_marker(circle)
      @overlays.push marker
      @get_map().addOverlay(marker);

  _get_bounding_extent_for_circles: (circles) =>
    coordinates =[]
    for circle in circles
      coordinates.push([circle.location.longitude, circle.location.latitude])
    ext = ol.extent.boundingExtent(coordinates)
    ext = ol.proj.transformExtent( ext, ol.proj.get('EPSG:4326'), ol.proj.get('EPSG:3857') )

    return ext

  _clear_markers: =>
    @overlays ||= []
    for overlay in @overlays
      @get_map().removeOverlay(overlay)
      @remove_marker(overlay)
    @overlays = []

  remove_marker: (overlay) ->
    el = $(overlay.getElement())
    el.off()
    el.removeClass('open')


  clear_circle: =>
    # console.log "clearing"
    @circleField.val ""

    $(".circle-marker").removeClass('open')


  select_circle: (circle) =>
    @clear_circle()
    # console.log "selected ", circle
    @circleField.val circle.id

    $("#circle-marker-#{circle.id}").addClass('open')



