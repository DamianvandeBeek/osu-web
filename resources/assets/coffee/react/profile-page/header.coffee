###
#    Copyright (c) ppy Pty Ltd <contact@ppy.sh>.
#
#    This file is part of osu!web. osu!web is distributed with the hope of
#    attracting more community contributions to the core ecosystem of osu!.
#
#    osu!web is free software: you can redistribute it and/or modify
#    it under the terms of the Affero GNU General Public License version 3
#    as published by the Free Software Foundation.
#
#    osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###

import { Badges } from './badges'
import { CoverSelector } from './cover-selector'
import { Detail } from './detail'
import { DetailMobile } from './detail-mobile'
import { GameModeSwitcher } from './game-mode-switcher'
import { HeaderInfo } from './header-info'
import { Links } from './links'
import { Stats } from './stats'
import * as React from 'react'
import HeaderV4 from 'header-v4'
import { Img2x } from 'img2x'
import { a, button, div, dd, dl, dt, h1, i, img, li, span, ul } from 'react-dom-factories'
import { Spinner } from 'spinner'
el = React.createElement


export class Header extends React.Component
  constructor: (props) ->
    super props

    @state =
      editing: false
      coverUrl: props.user.cover_url
      isCoverUpdating: false
      settingDefaultMode: false

    @coverSelector = React.createRef()
    @debouncedCoverSet = _.debounce @coverSet, 300


  componentDidMount: =>
    $.subscribe 'user:cover:reset.profilePageHeaderMain', @coverReset
    $.subscribe 'user:cover:set.profilePageHeaderMain', @debouncedCoverSet
    $.subscribe 'user:cover:upload:state.profilePageHeaderMain', @coverUploadState

    $.subscribe 'key:esc.profilePageHeaderMain', @closeEdit
    $(document).on 'click.profilePageHeaderMain', @closeEdit


  componentWillReceiveProps: (newProps) =>
    @debouncedCoverSet null, newProps.user.cover.url


  componentWillUnmount: =>
    $.unsubscribe '.profilePageHeaderMain'
    $(document).off '.profilePageHeaderMain'

    @closeEdit()
    @debouncedCoverSet.cancel()
    @xhr?.abort()


  render: =>
    div
      className: 'js-switchable-mode-page--scrollspy js-switchable-mode-page--page'
      'data-page-id': 'main'
      el HeaderV4,
        backgroundImage: @state.coverUrl
        isCoverUpdating: @state.isCoverUpdating
        links: @headerLinks()
        section: osu.trans 'layout.header.users._'
        subSection: osu.trans 'layout.header.users.show'
        theme: 'users'
        contentPrepend: @renderTournamentBanner()
        titleAppend: el GameModeSwitcher,
          currentMode: @props.currentMode
          user: @props.user
          withEdit: @props.withEdit

      div className: 'osu-page osu-page--users',
        div className: 'profile-header',
          div className: 'profile-header__top',
            el HeaderInfo, user: @props.user, currentMode: @props.currentMode, coverUrl: @state.coverUrl

            if !@props.user.is_bot
              el React.Fragment, null,
                el DetailMobile,
                  stats: @props.stats
                  userAchievements: @props.userAchievements
                  rankHistory: @props.rankHistory

                el Stats, stats: @props.stats

          if !@props.user.is_bot
            el Detail,
              stats: @props.stats
              userAchievements: @props.userAchievements
              rankHistory: @props.rankHistory
              user: @props.user

          if @props.user.badges.length > 0
            el Badges, badges: @props.user.badges

          el Links, user: @props.user

          @renderCoverSelector()


  renderCoverSelector: =>
    if @props.withEdit
      div
        ref: @coverSelector
        className: 'profile-header__cover-editor'
        button
          className: 'profile-page-toggle'
          title: osu.trans('users.show.edit.cover.button')
          onClick: @toggleEdit
          span className: 'fas fa-pencil-alt'
        if @state.editing
          el CoverSelector,
            canUpload: @props.user.is_supporter
            cover: @props.user.cover


  renderTournamentBanner: ({modifiers} = {}) =>
    return if !@props.user.active_tournament_banner.id?

    a
      href: laroute.route('tournaments.show', tournament: @props.user.active_tournament_banner.tournament_id)
      className: osu.classWithModifiers 'profile-tournament-banner', modifiers
      el Img2x,
        src: @props.user.active_tournament_banner.image
        className: 'profile-tournament-banner__image'


  closeEdit: (e) =>
    return unless @state.editing

    if e?
      return if e.button != 0
      return if $(e.target).closest(@coverSelector.current).length

    return if $('#overlay').is(':visible')
    return if document.body.classList.contains('modal-open')

    @setState editing: false, @coverReset


  coverReset: =>
    @debouncedCoverSet null, @props.user.cover.url


  coverSet: (_e, url) =>
    return if @state.isCoverUpdating

    @setState coverUrl: url


  coverUploadState: (_e, state) =>
    @setState isCoverUpdating: state


  headerLinks: =>
    links = [
      {
        url: laroute.route('users.show', user: @props.user.id)
        active: true
        title: osu.trans 'layout.header.users.show'
      }
    ]

    if !@props.user.is_bot
      links.push
        url: laroute.route('users.modding.index', user: @props.user.id)
        title: osu.trans 'layout.header.users.modding'

    links


  openEdit: =>
    @setState editing: true


  toggleEdit: =>
    if @state.editing
      @closeEdit()
    else
      @openEdit()


  setDefaultMode: =>
    @setState settingDefaultMode: true

    @xhr = $.ajax laroute.route('account.update'),
      method: 'PUT'
      data:
        user:
          playmode: @props.currentMode
    .done (data) ->
      $.publish 'user:update', data
    .fail (xhr, status) ->
      return if status == 'abort'

      osu.emitAjaxError() xhr
    .always =>
      @setState settingDefaultMode: false
