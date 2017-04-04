package com.jiguang.jbox.ui.drawer;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v7.widget.LinearLayoutManager;
import android.support.v7.widget.RecyclerView;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import com.activeandroid.query.Select;
import com.jiguang.jbox.AppApplication;
import com.jiguang.jbox.R;
import com.jiguang.jbox.ui.channel.ChannelActivity;
import com.jiguang.jbox.data.model.Channel;
import com.jiguang.jbox.ui.drawer.adapter.ChannelDrawerRecyclerViewAdapter;

import java.util.List;

/**
 * 侧边栏 Channel list.
 */
public class ChannelListFragment extends Fragment {

    private static final String TAG = ChannelListFragment.class.getSimpleName();

    private OnListFragmentInteractionListener mListener;
    private List<Channel> mChannels;

    private RecyclerView mRecyclerView;
    private ChannelDrawerRecyclerViewAdapter mAdapter;

    public ChannelListFragment() {
        if (!TextUtils.isEmpty(AppApplication.currentDevKey)) {
            mChannels = new Select().from(Channel.class)
                    .where("DevKey=? AND IsSubscribe=?", AppApplication.currentDevKey, true)
                    .execute();

            if (mChannels != null && !mChannels.isEmpty()) {
                AppApplication.currentChannelName = mChannels.get(0).name;
            }
        }
    }

    @SuppressWarnings("unused")
    public static ChannelListFragment newInstance(int columnCount) {
        return new ChannelListFragment();
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_drawer_channel, container, false);

        ImageView ivEdit = (ImageView) view.findViewById(R.id.iv_edit);
        ivEdit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(getActivity(), ChannelActivity.class);
                intent.putExtra(ChannelActivity.EXTRA_DEV_KEY, AppApplication.currentDevKey);
                startActivity(intent);
            }
        });

        Context context = view.getContext();
        mRecyclerView = (RecyclerView) view.findViewById(R.id.rv_channel);
        mRecyclerView.setLayoutManager(new LinearLayoutManager(context));
        mAdapter = new ChannelDrawerRecyclerViewAdapter(mChannels, mListener);
        mRecyclerView.setAdapter(mAdapter);

        return view;
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);
        if (context instanceof OnListFragmentInteractionListener) {
            mListener = (OnListFragmentInteractionListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnListFragmentInteractionListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    public void updateData(String devKey) {
        mChannels = new Select().from(Channel.class)
                .where("DevKey=? AND IsSubscribe=?", devKey, true)
                .execute();
        mAdapter = null;
        mAdapter = new ChannelDrawerRecyclerViewAdapter(mChannels, mListener);
        mRecyclerView.setAdapter(mAdapter);
    }

    public interface OnListFragmentInteractionListener {
        void onChannelListItemClick(Channel channel);
    }
}
