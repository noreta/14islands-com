###
#
# GoogleStreetviewPanorama component.
#
# For Sthlm6000 Case Study
#
# @author 14islands
#
###

class FOURTEEN.GoogleStreetviewPanorama extends FOURTEEN.ElementScrollVisibility

	ROTATE_DISTANCE = 0.1 #degrees per frame

	# @override FOURTEEN.BaseComponent.scripts
	scripts: [
		'https://maps.googleapis.com/maps/api/js?key=AIzaSyDhL8nwKWYtU4LdyiiMUp5zJ_8kRFRoAQA&v=3.exp&callback=FOURTEEN.onGoogleMapsLoaded'
	]


	constructor: (@$context, data) ->
		# FOURTEEN.ElementScrollVisibility()
		super(@$context, data)

		@panoramaHasLoaded_ = false
		@isScrolling_ = false

		@spinner = new FOURTEEN.Spinner @$context, {isBlack: true}
		@spinner.show()


	# @protected
	onReady: ->
		super() #FOURTEEN.ElementScrollVisibility.onReady

		# maps API already loaded, init panorama
		if google?.maps?.StreetViewPanorama?
			@onGoogleMapsApiLoaded_()
			FOURTEEN.onGoogleMapsLoaded = -> # empty function
		else
			# we need a global callback for the maps api load event
			FOURTEEN.onGoogleMapsLoaded = @onGoogleMapsApiLoaded_


	# @protected
	# @override FOURTEEN.ElementScrollVisibility.destroy
	destroy: ->
		super()
		@removeScrollEventListeners_()
		@cancelAutoRotate_()
		@panoramaHasLoaded_ = false
		@isScrolling_ = false
		if @pano_?
			@pano_.setVisible(false)
			@pano_ = undefined
		if google?
			google.maps.event.removeListener(@panoramaLoadListener_) if @panoramaLoadListener_?
			google.maps.event.removeListener(@panoramaPovListener_) if @panoramaPovListener_?
			google.maps.event.clearInstanceListeners(window)
			google.maps.event.clearInstanceListeners(document)
			google.maps.event.clearInstanceListeners(@$context[0])

	# @private
	# Google maps api loads a number of dependencies async and then calls this function
	onGoogleMapsApiLoaded_: =>
		panoramaOptions = {
			position: new google.maps.LatLng( @$context.data('latitude'), @$context.data('longitude') )
			disableDefaultUI: true
			scrollwheel: false
			pov: {
				heading: 105
				pitch: 0
			}
			zoom: 1
		}

		@pano_ = new google.maps.StreetViewPanorama( @$context[0], panoramaOptions )
		@pano_.setVisible(false)

		@panoramaLoadListener_ = google.maps.event.addListener(@pano_,
		                                                       'pano_changed',
		                                                       @onPanoLoaded_)

		@panoramaPovListener_ = google.maps.event.addListener(@pano_,
		                                                     'pov_changed',
		                                                      @cancelAutoRotate_)


	# @private
	autoRotate_: =>
		if @panoramaHasLoaded_ and @isFullyInViewport and not @isScrolling_
			pov = @pano_.getPov()
			pov.heading += ROTATE_DISTANCE
			@pano_.setPov(pov)
			@animationFrame_ = requestAnimationFrame(@autoRotate_)


	# @private
	cancelAutoRotate_: =>
		cancelAnimationFrame(@animationFrame_)


	# @private
	onPanoLoaded_: =>
		unless @panoramaHasLoaded_
			@spinner.hide(=>
				@$context.addClass('js-has-loaded')
				@panoramaHasLoaded_ = true
				@pano_.setVisible(true)
				if @isInViewport
					@autoRotate_()
			)


	# @private
	bindScrollEventListeners_: ->
		@$document.on(FOURTEEN.ScrollState.EVENT_SCROLL_START, @onScrollStart_)
		@$document.on(FOURTEEN.ScrollState.EVENT_SCROLL_STOP, @onScrollStop_)


	# @private
	removeScrollEventListeners_: ->
		@$document.off(FOURTEEN.ScrollState.EVENT_SCROLL_START, @onScrollStart_)
		@$document.off(FOURTEEN.ScrollState.EVENT_SCROLL_STOP, @onScrollStop_)


	# @private
	onScrollStart_: =>
		@isScrolling_ = true
		@cancelAutoRotate_()


	# @private
	onScrollStop_: =>
		@isScrolling_ = false
		@autoRotate_()


	# @protected
	onEnterViewport: =>
		super()
		@bindScrollEventListeners_()


	# @protected
	onExitViewport: =>
		super()
		@removeScrollEventListeners_()
		@cancelAutoRotate_()

