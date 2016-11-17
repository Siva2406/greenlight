# Recordings class

_recordingsInstance = null

class @Recordings
  constructor: ->
    # configure the datatable for recordings
    this.table = $('#recordings').dataTable({
      data: [],
      rowId: 'id',
      paging: false,
      searching: false,
      info: false,
      order: [[ 0, "desc" ]],
      language: {
        emptyTable: " "
      },
      columns: [
        { data: "start_time" },
        { data: "previews" },
        { data: "duration" },
        { data: "playbacks" },
        { data: "id" }
      ],
      columnDefs: [
        {
          targets: 0,
          render: (data, type, row) ->
            if type == 'display'
              return new Date(data)
                .toLocaleString($('html').attr('lang'),
                  {month: 'long', day: 'numeric', year: 'numeric',
                  hour12: 'true', hour: '2-digit', minute: '2-digit'})
            return data
        },
        {
          targets: 1,
          render: (data, type, row) ->
            if type == 'display'
              str = ''
              for d in data
                str += '<img height="50" width="50" src="'+d.url+'" alt="'+d.alt+'"></img> '
              return str
            return data
        },
        {
          targets: 3,
          render: (data, type, row) ->
            if type == 'display'
              str = ''
              if row.published
                for d in data
                  str += '<a href="'+d.url+'">'+d.type_i18n+'</a> '
              return str
            return data
        },
        {
          targets: -1,
          render: (data, type, row) ->
            if type == 'display'
              roomName = Meeting.getInstance().getId()
              published = row.published
              icon = getPublishClass(published)
              publishText = if published then 'publish' else 'unpublish'
              recordingActions = $('.hidden-elements').find('.recording-actions')
              recordingActions.find('.recording-update > i')
                .removeClass()
                .addClass('fa '+icon)
              recordingActions.find('.recording-update')
                .attr('data-published', published)
                .attr('title', I18n[publishText+'_recording'])
              return recordingActions.html()
            return data
        }
      ]
    })

  # Gets the current instance or creates a new one
  @getInstance: ->
    if _recordingsInstance && Recordings.initialized()
      return _recordingsInstance
    _recordingsInstance = new Recordings()
    return _recordingsInstance

  @initialize: ->
    Recordings.getInstance()

  @initialized: ->
    return $.fn.DataTable.isDataTable('#recordings') && _recordingsInstance

  # refresh the recordings from the server
  refresh: ->
    _this = this
    table_api = this.table.api()
    $.get "/rooms/"+Meeting.getInstance().getId()+"/recordings", (data) ->
      if !data.is_owner
        table_api.column(-1).visible(false)
      for recording in data.recordings
        totalMinutes = Math.round((new Date(recording.end_time) - new Date(recording.start_time)) / 1000 / 60)
        recording.duration = totalMinutes
      data.recordings.sort (a,b) ->
        return new Date(b.start_time) - new Date(a.start_time)
      table_api.clear()
      table_api.rows.add(data.recordings)
      table_api.columns.adjust().draw()

  # setup click handlers for the action buttons
  setupActionHandlers: ->
    table_api = this.table.api()
    this.table.on 'click', '.recording-update', (event) ->
      btn = $(this)
      row = table_api.row($(this).closest('tr')).data()
      url = $('.meeting-url').val()
      id = row.id
      published = btn.data('published')
      btn.prop('disabled', true)
      $.ajax({
        method: 'PATCH',
        url: url+'/recordings/'+id,
        data: {published: (!published).toString()}
      }).done((data) ->

      ).fail((data) ->
        btn.prop('disabled', false)
      )

    this.table.on 'click', '.recording-delete', (event) ->
      btn = $(this)
      row = table_api.row($(this).closest('tr')).data()
      url = $('.meeting-url').val()
      id = row.id
      btn.prop('disabled', true)
      $.ajax({
        method: 'DELETE',
        url: url+'/recordings/'+id
      }).done((data) ->

      ).fail((data) ->
        btn.prop('disabled', false)
      )