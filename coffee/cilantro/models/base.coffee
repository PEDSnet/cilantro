define [
    '../core'
], (c) ->

    class Model extends c.Backbone.Model
        url: ->
            if @isNew() then super else @links.self

        constructor: (attrs, options) ->
            @links = {}
            super(attrs, options)

        parse: (attrs, options) ->
            if attrs? and attrs._links?
                @links = {}
                for name, link of attrs._links
                    @links[name] = link.href
            return attrs


    class Collection extends c.Backbone.Collection
        model: Model

        url: ->
            if @isNew() then super else @links.self

        constructor: (attrs, options) ->
            @links = {}
            super(attrs, options)

        fetch: (options) ->
            options = options or {}
            options.cache = false
            return c.Backbone.Collection.prototype.fetch.call(this, options)

        parse: (attrs, options) ->
            if attrs? and attrs._links?
                @links = {}
                for name, link of attrs._links
                    @links[name] = link.href
            return attrs


    { Model, Collection }
