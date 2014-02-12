define [
    'underscore'
    'backbone'
    'marionette'
    '../base'
    './info'
    './stats'
    './types'
    '../controls'
    '../charts'
], (_, Backbone, Marionette, base, info, stats, types, controls, charts) ->

    fieldTypeControls =
        choice: controls.InfographControl
        number: controls.NumberControl
        date: controls.DateControl
        time: controls.DateControl
        datetime: controls.DateControl

    defaultFieldControl = controls.SearchControl


    class LoadingFields extends base.LoadView
        message: 'Loading fields...'

    class LoadingControls extends base.LoadView
        message: 'Loading and rendering controls...'


    class FieldControls extends Marionette.CollectionView
        emptyView: LoadingControls

        getItemView: (model) ->
            # If the options specify an explicit view class use it. Otherwise
            # fallback to infering the interface based on the field's type
            if not (itemView = model.get('itemView'))
                if not (fieldType = model.get('fieldType'))
                    fieldType = types.getFieldType(model.get('field'))

                if fieldTypeControls[fieldType]
                    itemView = fieldTypeControls[fieldType]
                else
                    itemView = defaultFieldControl

            return itemView

        itemViewOptions: (model, index) ->
            return {
                context: model.get('context')
                model: model.get('field')
                index: index
            }

        buildItemView: (model, itemView, options) ->
            return new itemView(options)


    # Stores the view class and various options for a control. This is
    # used by FieldForm for adding new controls to the UI. A new instance
    # is created by specifying the `viewClass`. Any additional options will
    # be passed into the constructor of the view when initialized.
    class FieldControlOptions extends Backbone.Model


    # Contained within the ConceptForm containing views for a single FieldModel
    class FieldForm extends Marionette.Layout
        className: 'field-form'

        getTemplate: ->
            if @options.condensedLayout
                'field/form-condensed'
            else
                'field/form'

        options:
            nodeType: 'condition'
            showInfo: true
            showChart: false
            showStats: true
            showDefaultControl: true
            condensedLayout: false
            fieldType: null

        constructor: ->
            super

            @context = @options.context.define
                concept: @options.context.get('concept')
                field: @model.id
            , type: @options.nodeType

        regions:
            info: '.info-region'
            stats: '.stats-region'
            controls: '.controls-region'

        regionViews:
            info: info.FieldInfo
            stats: stats.FieldStats
            controls: FieldControls

        onRender: ->
            if @options.showInfo
                @info.show new @regionViews.info
                    model: @model

            if @options.showStats and @model.stats?
                @stats.show new @regionViews.stats
                    model: @model

            # Initialize empty collection view in which controls can
            # be added to.
            @controls.show new @regionViews.controls
                collection: new Backbone.Collection
                context: @context

            # Add the default control
            if @options.showDefaultControl
                @addControl()

            # HACK
            # Only represent for fields that support distributions. This
            # enumerable condition is a hack since the above control
            # may already have chart-like display...and the hack grows deeper
            # to prevent a chart being added when dealing with dates...
            if @model.get('simple_type') is 'number' and not @model.get('enumerable')
                if @options.showChart and @model.links.distribution?
                    @addControl charts.FieldChart,
                        chart:
                            height: 200

            if @options.condensedLayout
                @$el.addClass('condensed')

        addControl: (itemView, options) ->
            model = new FieldControlOptions _.defaults
                context: @context
                field: @model
                fieldType: @options.fieldType
                itemView: itemView
            , options

            @controls.currentView.collection.add(model)


    class FieldFormCollection extends Marionette.CollectionView
        itemView: FieldForm

        emptyView: LoadingFields

        itemViewOptions: (model, index) ->
            options = _.extend {}, @options,
                model: model
                context: @options.context

            # This collection is used by a concept, therefore if only one
            # field is present, the concept name and description take
            # precedence
            if @options.hideSingleFieldInfo and @collection.length < 2
                options.showInfo = false

            # Only check if another is not already rendered
            if not @fieldChartIndex?
                if options.showChart isnt false and model.links?.distribution?
                    @fieldChartIndex = index
                    options.showChart = true
            else
                options.condensedLayout = true

            return options


    { FieldControls, FieldForm, FieldFormCollection }
