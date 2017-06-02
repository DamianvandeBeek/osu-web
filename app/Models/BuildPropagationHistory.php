<?php

/**
 *    Copyright 2015-2017 ppy Pty. Ltd.
 *
 *    This file is part of osu!web. osu!web is distributed with the hope of
 *    attracting more community contributions to the core ecosystem of osu!.
 *
 *    osu!web is free software: you can redistribute it and/or modify
 *    it under the terms of the Affero GNU General Public License version 3
 *    as published by the Free Software Foundation.
 *
 *    osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
 *    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *    See the GNU Affero General Public License for more details.
 *
 *    You should have received a copy of the GNU Affero General Public License
 *    along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace App\Models;

use DB;
use Illuminate\Database\Eloquent\Model;

class BuildPropagationHistory extends Model
{
    protected $guarded = [];

    public $timestamps = false;
    protected $dates = [
        'created_at',
    ];

    public function build()
    {
        return $this->belongsTo(Build::class, 'build_id');
    }

    public function scopeChangelog($query)
    {
        $buildsTable = with(new Build)->getTable();
        $propagationTable = with(new BuildPropagationHistory)->getTable();
        $streamsTable = 'osu_updates.'.with(new UpdateStream)->getTable();

        $query->join($buildsTable, "{$buildsTable}.build_id", '=', "{$propagationTable}.build_id")
            ->join($streamsTable, "{$streamsTable}.stream_id", '=', "{$buildsTable}.stream_id")
            ->select(DB::raw('created_at, pretty_name, sum(user_count) as user_count'))
            ->groupBy(['created_at', 'pretty_name'])
            ->orderBy('created_at', 'asc');
    }
}
